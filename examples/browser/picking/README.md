# Browser Picking Example

This example uses `Three::Raycaster` to pick Ruby-authored meshes from browser click coordinates, map three.js intersections back to Ruby `Object3D` instances, and update the selected mesh material.

Install browser dependencies and serve the repository root over HTTP:

```sh
pnpm install
ruby -run -e httpd . -p 8000
```

Then open:

```text
http://localhost:8000/examples/browser/picking/
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
pnpm test:browser:picking
```
