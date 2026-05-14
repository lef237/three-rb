# Browser Textures Example

This example renders Ruby-authored textured meshes through ruby.wasm and the JavaScript three.js renderer. It focuses on `TextureLoader`, `RGBELoader`, repeat/wrap/filter settings, `MeshPhysicalMaterial`, `MeshMatcapMaterial`, `MeshToonMaterial`, standard plus physical material texture maps, matcap and toon gradient texture assignment, and an HDR environment texture.

Install browser dependencies and serve the repository root over HTTP:

```sh
pnpm install
ruby -run -e httpd . -p 8000
```

Then open:

```text
http://localhost:8000/examples/browser/textures/
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
pnpm test:browser:textures
```

The smoke test serves the repository root, waits for the Ruby scene to reach `Running`, samples the WebGL canvas for nonblank pixels, verifies the textured meshes, physical, matcap, and toon material parameters, RGBE environment mapping, and checks that repeat/wrap/filter settings reach the three.js texture.
