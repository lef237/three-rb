# three-rb dango browser example

This example renders a Ruby-authored three-color dango scene through ruby.wasm and three.js. It focuses on composing a recognizable 3D object from `SphereGeometry`, `BoxGeometry`, grouped meshes, glossy `MeshPhongMaterial`, lambertian supporting objects, shadows, and `OrbitControls`.

## Run

From the repository root:

```sh
pnpm install
ruby -run -e httpd . -p 8000
```

Open:

```text
http://localhost:8000/examples/browser/dango/
```

## Smoke Test

```sh
pnpm test:browser:dango
```

The smoke test serves the repository root, waits for the Ruby scene to reach `Running`, samples the WebGL canvas for nonblank pixels, verifies the three mochi meshes and skewer materialize with the expected geometry and colors, and confirms animation frames are rendered.
