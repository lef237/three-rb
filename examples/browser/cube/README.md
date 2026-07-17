# Browser Cube Example

This example renders a Ruby-authored cube through ruby.wasm and the JavaScript three.js renderer.

Install browser dependencies and serve the repository root over HTTP:

```sh
pnpm install
ruby -run -e httpd . -p 8000
```

Then open:

```text
http://localhost:8000/examples/browser/cube/
```

The page uses these pnpm-managed browser dependencies:

- `@ruby/3.4-wasm-wasi@2.9.4-2026-05-11-a`
- `@ruby/wasm-wasi@2.9.4-2026-05-11-a`
- `three@0.185.1`

The repository root must be served, not only this directory, because `boot.mjs` loads browser packages from `node_modules/` and `main.rb` loads the library source from `lib/`.

## Browser Smoke Test

Install the optional Node dependency and browser binary:

```sh
pnpm install
pnpm exec playwright install chromium
```

Run the browser smoke test:

```sh
pnpm test:browser:cube
```

The smoke test serves the repository root, waits for the Ruby scene to reach `Running`, samples the WebGL canvas for nonblank pixels, and verifies that the renderer drew the cube triangles.
