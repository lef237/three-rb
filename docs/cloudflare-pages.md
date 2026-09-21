# Cloudflare Pages Deployment

This guide shows how to deploy a three-rb browser example to Cloudflare Pages.

Cloudflare Pages does not run the example's Ruby code on the server. Pages serves static files, the browser downloads ruby.wasm, and ruby.wasm runs the Ruby entrypoint in the user's browser.

## What Must Be Deployed

The current browser examples use root-relative URLs. The deployed output must preserve these paths:

- `/examples/browser/ruby/` for the Ruby gemstone example page, boot file, Ruby entrypoint, and local assets.
- `/examples/browser/shared/` for the shared JavaScript boot runtime.
- `/vendor/@ruby/wasm-wasi/` for the browser Ruby VM JavaScript package.
- `/vendor/@bjorn3/browser_wasi_shim/` for WASI browser support.
- `/vendor/three/` for three.js and its addons.
- `/` for the public demo entrypoint generated from the Ruby example page.

`/lib` is not deployed. The build script bundles the Ruby entrypoint and everything it reaches through `require_relative` into a single `dist/examples/browser/ruby/main.rb`, so the browser Ruby VM fetches one file instead of one per source file. See "Bundled Ruby Source" below.

Do not set `examples/browser/ruby` itself as the Cloudflare Pages output directory. That directory alone does not contain `/examples/browser/shared` or the required browser packages.

Cloudflare Pages has a 25 MiB maximum size for each static asset. The current `ruby+stdlib.wasm` file is larger than that limit, so the Pages build script does not upload it as a Pages asset. Instead, the generated `dist/examples/browser/shared/config.mjs` points at a CDN URL for the pinned `@ruby/3.4-wasm-wasi` package by default. If you prefer to own that asset, upload `node_modules/@ruby/3.4-wasm-wasi/dist/ruby+stdlib.wasm` to Cloudflare R2 or another static host that supports large files and set `RUBY_WASM_URL` to that public URL in the Pages environment.

Do not point `RUBY_WASM_URL` at an R2 `pub-*.r2.dev` URL. That endpoint is rate limited, is documented as development-only, and is not served through the Cloudflare CDN cache, so every visitor downloads the full 30 MB from the bucket itself. Attach a custom domain to the bucket, or serve it from a Worker, so the file is cached at the edge.

The Pages build script copies browser packages under `/vendor/` instead of `/node_modules/`. This avoids Pages deployments that omit or fail to serve `node_modules` paths, and keeps the deployed URLs separate from package-manager internals.

## Local Verification

Install the browser dependencies and run the existing smoke test:

```sh
pnpm install
pnpm test:browser:ruby
```

The smoke test starts a local static HTTP server and verifies that the Ruby VM boots, the Ruby scene loads, and three.js renders visible pixels. Use `http://...` URLs for manual testing; `file://` will not work because the runtime fetches ES modules, wasm, Ruby files, and assets.

## Recommended Output Directory

Create a deployment directory that contains only the static files required by the example:

```sh
pnpm run build:pages:ruby
```

This script rebuilds `dist/` from scratch, copies the Ruby example, shared browser boot runtime, and required browser packages, and bundles the Ruby entrypoint. It also generates `dist/index.html` and `dist/boot.mjs` so the public Pages root URL runs the Ruby example directly. It uses `cp -RL` for packages copied from local `node_modules` so pnpm symlinks are resolved into real files, then deploys those package files under `/vendor/`. Cloudflare Pages uploads the output directory contents, and a copied symlink to `.pnpm/...` will not work unless the referenced package store is also present in the deployment.

By default, the script writes a Pages-specific wasm URL into `dist/examples/browser/shared/config.mjs`, pinned to the `@ruby/3.4-wasm-wasi` version in `package.json`:

```text
https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@<version>/dist/ruby+stdlib.wasm
```

The build fails if `@ruby/3.4-wasm-wasi` and `@ruby/wasm-wasi` are on different versions, because the wasm binary and the JavaScript glue that loads it must match.

To use an R2-hosted copy or another large-file host, set `RUBY_WASM_URL` before the build command.

Run the same shape locally before deploying:

```sh
ruby -run -e httpd dist -p 8000
```

Open:

```text
http://localhost:8000/
```

If you rebuild `dist/` locally, start from an empty output directory so stale files do not hide missing copy steps.

## Bundled Ruby Source

The browser Ruby VM resolves `require_relative` over HTTP, one request per source file, and those requests are sequential. The gemstone example reaches 83 files, so an unbundled deployment pays 83 round trips before the scene can run. On a connection with 200 ms of latency that is roughly 17 seconds of waiting on its own.

`scripts/bundle-ruby.mjs` inlines those files into a single entrypoint at build time:

```sh
node scripts/bundle-ruby.mjs examples/browser/ruby/main.rb dist/examples/browser/ruby/main.rb
```

Only literal top-level `require_relative "path"` lines are inlined, matching what `JS::RequireRemote` itself resolves. `require "json"` and other standard library requires are left alone, and each file is included once, in the order Ruby would have loaded it.

Local development and the smoke tests still serve the repository root and still load the unbundled sources, so `require_relative` stays the way you edit the code.

## Optional Headers

Cloudflare Pages normally serves static assets with appropriate content types. The runtime also falls back when `.wasm` is not served as `application/wasm`, but using the wasm content type is faster because it allows streaming compilation.

Add this file at `dist/_headers` if you want to force the wasm MIME type:

```text
/*.wasm
  Content-Type: application/wasm
```

If you later add a Content Security Policy, make sure it still allows same-origin JavaScript modules, WebAssembly compilation, same-origin fetches, and WebGL. The example does not need a custom CSP by default.

## Cloudflare Pages Settings

Create a Pages project from the repository and use these settings:

```text
Framework preset: None
Build command: pnpm run build:pages:ruby
Build output directory: dist
```

Set this environment variable to match the package manager version declared in `package.json`:

```text
PNPM_VERSION=11.1.1
```

Optional, if you host `ruby+stdlib.wasm` yourself:

```text
RUBY_WASM_URL=https://<your-static-host>/ruby+stdlib.wasm
```

Cloudflare Pages installs dependencies from `package.json` before the build command unless dependency installation is disabled. The build command creates `dist/` on Cloudflare during each deployment, so `dist/` should not be committed to the repository. Cloudflare's Ruby support is only needed for build-time commands; the deployed Pages runtime still serves static files.

After deployment, open:

```text
https://<project>.pages.dev/
```

## Direct Upload With Wrangler

For a manual deployment, build the output directory locally and upload it:

```sh
pnpm install
pnpm run build:pages:ruby
pnpm exec wrangler pages deploy dist --project-name <project>
```

Open the deployed Pages root URL after Wrangler prints it.

## Deploying A Different Example

For another browser example, copy that example directory instead of `examples/browser/ruby`:

```sh
cp -R examples/browser/cube dist/examples/browser/cube
```

Then open:

```text
https://<project>.pages.dev/examples/browser/cube/
```

Keep `examples/browser/shared` and the same browser packages in the output directory, and bundle that example's entrypoint the same way. Examples with local files under `assets/` need those assets copied with the example directory.

## Troubleshooting

`Failed to load ruby.wasm: 404`

The configured wasm URL is not reachable. For Cloudflare Pages, do not rely on `/node_modules/@ruby/3.4-wasm-wasi/dist/ruby+stdlib.wasm` as a Pages asset: that file is larger than Pages' 25 MiB single-file limit. Use the default CDN URL generated by `pnpm run build:pages:ruby`, or set `RUBY_WASM_URL` to a public R2/CDN URL.

`Failed to resolve module specifier`

The import map in the example page points at `/node_modules/...`, but the matching package was not copied to the output directory.

`/node_modules/three/examples/jsm/... not found`

The deployed site is using an older output layout or the output directory contains pnpm symlinks instead of package files. Rebuild `dist/` from an empty directory with `pnpm run build:pages:ruby`, then confirm the expected addon exists under `/vendor/`:

```sh
test -f dist/vendor/three/examples/jsm/postprocessing/UnrealBloomPass.js
```

Ruby `require_relative` errors

The deployed `main.rb` was copied instead of bundled, or the example was moved without updating its relative Ruby paths. Confirm the deployed entrypoint is the generated bundle:

```sh
head -2 dist/examples/browser/ruby/main.rb
grep -c require_relative dist/examples/browser/ruby/main.rb
```

The second command should print `0`.

The status stays at `Loading ruby.wasm`

The boot runtime aborts and retries the wasm download up to three times if it stops making progress for 20 seconds, and the status line shows `Retrying ruby.wasm download (n/3)` while it does. If it still fails, check the browser network tab for failed `.wasm`, `.mjs`, `.rb`, `.hdr`, or three.js addon requests. A missing static asset is the most common cause.

If the download completes but is simply slow for everyone, the wasm host is the problem rather than the page. Check whether the host returns a `cf-cache-status` header; an endpoint that never does is not being cached at the edge.

The canvas is blank after the status says `Running`

Run `pnpm test:browser:ruby` locally first. If the smoke test passes locally, compare the deployed network responses and browser console errors with the local server.

## Limitations

The Ruby source files are public static assets because the browser Ruby VM fetches them over HTTP.

Cloudflare Pages Functions are not a Ruby server runtime. If the app needs server-side behavior, implement it in Pages Functions or Workers and keep the three-rb browser scene as a static client.

The current examples assume root-relative paths. If you need to serve them from a nested path behind another proxy, update the import map, wasm URL, `JS::RequireRemote.instance.base_url`, and any asset URLs in the Ruby entrypoint.
