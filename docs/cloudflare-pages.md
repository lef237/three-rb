# Cloudflare Pages Deployment

This guide shows how to deploy a three-rb browser example to Cloudflare Pages.

Cloudflare Pages does not run the example's Ruby code on the server. Pages serves static files, the browser downloads ruby.wasm, and ruby.wasm runs the Ruby entrypoint in the user's browser.

## What Must Be Deployed

The current browser examples use root-relative URLs. The deployed output must preserve these paths:

- `/examples/browser/ruby/` for the Ruby gemstone example page, boot file, Ruby entrypoint, and local assets.
- `/examples/browser/shared/` for the shared JavaScript boot runtime.
- `/lib/` for the three-rb Ruby source files loaded by `require_relative`.
- `/node_modules/@ruby/3.4-wasm-wasi/` for `ruby+stdlib.wasm`.
- `/node_modules/@ruby/wasm-wasi/` for the browser Ruby VM JavaScript package.
- `/node_modules/@bjorn3/browser_wasi_shim/` for WASI browser support.
- `/node_modules/three/` for three.js and its addons.

Do not set `examples/browser/ruby` itself as the Cloudflare Pages output directory. That directory alone does not contain `/lib`, `/examples/browser/shared`, or the required browser packages.

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
rm -rf dist
mkdir -p dist/examples/browser
mkdir -p dist/node_modules/@ruby
mkdir -p dist/node_modules/@bjorn3
mkdir -p dist/node_modules

cp -R examples/browser/ruby dist/examples/browser/ruby
cp -R examples/browser/shared dist/examples/browser/shared
cp -R lib dist/lib
cp -RL node_modules/@ruby/3.4-wasm-wasi dist/node_modules/@ruby/3.4-wasm-wasi
cp -RL node_modules/@ruby/wasm-wasi dist/node_modules/@ruby/wasm-wasi
cp -RL node_modules/@bjorn3/browser_wasi_shim dist/node_modules/@bjorn3/browser_wasi_shim
cp -RL node_modules/three dist/node_modules/three
```

Use `cp -RL` for packages copied from `node_modules` so pnpm symlinks are resolved into real files. Cloudflare Pages uploads the output directory contents, and a copied symlink to `.pnpm/...` will not work unless the referenced package store is also present in the deployment.

Run the same shape locally before deploying:

```sh
ruby -run -e httpd dist -p 8000
```

Open:

```text
http://localhost:8000/examples/browser/ruby/
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
Build command: <copy files into dist>
Build output directory: dist
```

Set this environment variable to match the package manager version declared in `package.json`:

```text
PNPM_VERSION=11.1.1
```

Cloudflare Pages installs dependencies from `package.json` before the build command unless dependency installation is disabled. The build command may be the copy commands above, but it is usually cleaner to wrap them in a package script such as `pnpm run build:pages:ruby`. Cloudflare's Ruby support is only needed for build-time commands; the deployed Pages runtime still serves static files.

After deployment, open:

```text
https://<project>.pages.dev/examples/browser/ruby/
```

## Direct Upload With Wrangler

For a manual deployment, build the output directory locally and upload it:

```sh
pnpm install
rm -rf dist
mkdir -p dist/examples/browser
mkdir -p dist/node_modules/@ruby
mkdir -p dist/node_modules/@bjorn3
mkdir -p dist/node_modules
cp -R examples/browser/ruby dist/examples/browser/ruby
cp -R examples/browser/shared dist/examples/browser/shared
cp -R lib dist/lib
cp -RL node_modules/@ruby/3.4-wasm-wasi dist/node_modules/@ruby/3.4-wasm-wasi
cp -RL node_modules/@ruby/wasm-wasi dist/node_modules/@ruby/wasm-wasi
cp -RL node_modules/@bjorn3/browser_wasi_shim dist/node_modules/@bjorn3/browser_wasi_shim
cp -RL node_modules/three dist/node_modules/three
pnpm exec wrangler pages deploy dist --project-name <project>
```

Open the deployed `/examples/browser/ruby/` path after Wrangler prints the Pages URL.

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

The output directory is missing `/node_modules/@ruby/3.4-wasm-wasi/dist/ruby+stdlib.wasm`, or the deployment is not mounted at the domain root.

`Failed to resolve module specifier`

The import map in the example page points at `/node_modules/...`, but the matching package was not copied to the output directory.

`/node_modules/three/examples/jsm/... not found`

The output directory probably contains pnpm symlinks instead of package files. Rebuild `dist/` from an empty directory and copy packages with `cp -RL`, then confirm the expected addon exists:

```sh
test -f dist/node_modules/three/examples/jsm/postprocessing/UnrealBloomPass.js
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
