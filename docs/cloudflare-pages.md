# Cloudflare Pages Deployment

This guide shows how to deploy a three-rb browser example to Cloudflare Pages.

Cloudflare Pages does not run the example's Ruby code on the server. Pages serves static files, the browser downloads ruby.wasm, and ruby.wasm runs the Ruby entrypoint in the user's browser.

## What Must Be Deployed

The current browser examples use root-relative URLs. The deployed output must preserve these paths:

- `/examples/browser/ruby/` for the Ruby gemstone example page, boot file, Ruby entrypoint, and local assets.
- `/examples/browser/shared/` for the shared JavaScript boot runtime.
- `/lib/` for the three-rb Ruby source files loaded by `require_relative`.
- `/vendor/@ruby/wasm-wasi/` for the browser Ruby VM JavaScript package.
- `/vendor/@bjorn3/browser_wasi_shim/` for WASI browser support.
- `/vendor/three/` for three.js and its addons.
- `/` for the public demo entrypoint generated from the Ruby example page.

Do not set `examples/browser/ruby` itself as the Cloudflare Pages output directory. That directory alone does not contain `/lib`, `/examples/browser/shared`, or the required browser packages.

Cloudflare Pages has a 25 MiB maximum size for each static asset. The current `ruby+stdlib.wasm` file is larger than that limit, so the Pages build script does not upload it as a Pages asset. Instead, the generated `dist/examples/browser/shared/config.mjs` points at a CDN URL for the pinned `@ruby/3.4-wasm-wasi` package by default. If you prefer to own that asset, upload `node_modules/@ruby/3.4-wasm-wasi/dist/ruby+stdlib.wasm` to Cloudflare R2 or another static host that supports large files and set `RUBY_WASM_URL` to that public URL in the Pages environment.

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

This script rebuilds `dist/` from scratch, copies the Ruby example, shared browser boot runtime, local Ruby source, and required browser packages. It also generates `dist/index.html` and `dist/boot.mjs` so the public Pages root URL runs the Ruby example directly. It uses `cp -RL` for packages copied from local `node_modules` so pnpm symlinks are resolved into real files, then deploys those package files under `/vendor/`. Cloudflare Pages uploads the output directory contents, and a copied symlink to `.pnpm/...` will not work unless the referenced package store is also present in the deployment.

By default, the script writes a Pages-specific wasm URL into `dist/examples/browser/shared/config.mjs`:

```text
https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@2.9.4-2026-05-11-a/dist/ruby+stdlib.wasm
```

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

Keep `examples/browser/shared`, `lib`, and the same browser packages in the output directory. Examples with local files under `assets/` need those assets copied with the example directory.

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

The output directory is missing `/lib`, or the example was moved without updating its relative Ruby paths.

The status stays at `Loading ruby.wasm`

Check the browser network tab for failed `.wasm`, `.mjs`, `.rb`, `.hdr`, or three.js addon requests. A missing static asset is the most common cause.

The canvas is blank after the status says `Running`

Run `pnpm test:browser:ruby` locally first. If the smoke test passes locally, compare the deployed network responses and browser console errors with the local server.

## Limitations

The Ruby source files are public static assets because the browser Ruby VM fetches them over HTTP.

Cloudflare Pages Functions are not a Ruby server runtime. If the app needs server-side behavior, implement it in Pages Functions or Workers and keep the three-rb browser scene as a static client.

The current examples assume root-relative paths. If you need to serve them from a nested path behind another proxy, update the import map, wasm URL, `JS::RequireRemote.instance.base_url`, and any asset URLs in the Ruby entrypoint.
