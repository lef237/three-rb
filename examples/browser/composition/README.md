# Browser Composition Example

This example renders a Ruby-authored scene through ruby.wasm and the JavaScript three.js renderer. It uses a `PlaneGeometry` backdrop, `SphereGeometry`, grouped child meshes, `TextureLoader` repeat/wrap/filter settings, `MeshLambertMaterial`, `MeshNormalMaterial`, `OrbitControls`, and a material color update in the animation loop.

Install browser dependencies and serve the repository root over HTTP:

```sh
pnpm install
ruby -run -e httpd . -p 8000
```

Then open:

```text
http://localhost:8000/examples/browser/composition/
```

The repository root must be served, not only this directory, because `boot.mjs` loads browser packages from `node_modules/` and `main.rb` loads the library source from `lib/`.

## Browser Smoke Test

Install the optional Node dependency and browser binary:

```sh
pnpm install
pnpm exec playwright install chromium
```

Run the browser smoke test:

```sh
pnpm test:browser:composition
```

The smoke test serves the repository root, waits for the Ruby scene to reach `Running`, samples the WebGL canvas for nonblank pixels, verifies grouped meshes, `PlaneGeometry`, `SphereGeometry`, `TextureLoader` repeat/wrap/filter settings, `MeshLambertMaterial`, `MeshNormalMaterial`, and `OrbitControls`, then confirms that material changes and camera drag controls reach the renderer.
