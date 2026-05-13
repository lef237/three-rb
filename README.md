# three.rb
Ruby 3D Library.

## Status

This project is in the initial implementation phase. The current code covers the gem foundation, math primitives, scene graph basics, initial geometry/material objects, dirty-tracked backend sync, browser examples, and the first three.js backend/renderer bridge.

## Quick Start

```ruby
require "three"

scene = Three::Scene.new
camera = Three::PerspectiveCamera.new(75, aspect: 16.0 / 9.0)
camera.position.z = 5

geometry = Three::BoxGeometry.new(1, 1, 1)
material = Three::MeshBasicMaterial.new(color: 0x00ff00)
cube = Three::Mesh.new(geometry, material)

scene.add(cube)
```

Browser rendering is being wired through `Three::Renderers::ThreeJSRenderer`, which targets three.js from ruby.wasm.

## Browser Example

Install browser dependencies, serve the repository root, and open one of the browser examples:

```sh
pnpm install
ruby -run -e httpd . -p 8000
```

```text
http://localhost:8000/examples/browser/cube/
http://localhost:8000/examples/browser/composition/
http://localhost:8000/examples/browser/textures/
http://localhost:8000/examples/browser/cubemap/
http://localhost:8000/examples/browser/gltf/
http://localhost:8000/examples/browser/serialization/
http://localhost:8000/examples/browser/picking/
```

The example loads pnpm-managed browser packages from `node_modules/`: `@ruby/3.4-wasm-wasi@2.9.4-2026-05-11-a`, `@ruby/wasm-wasi@2.9.4-2026-05-11-a`, and `three@0.184.0`.

Run the optional browser smoke tests:

```sh
pnpm install
pnpm exec playwright install chromium
pnpm test:browser
```

Run the optional browser sync benchmarks:

```sh
pnpm benchmark:browser
pnpm benchmark:browser:mesh-sync
pnpm benchmark:browser:instanced-mesh-sync
```

## Development

Install dependencies:

```sh
bundle install
```

Run tests:

```sh
bundle exec rake test
```

Export a Ruby-authored scene to a deterministic JSON-friendly hash:

```ruby
exported = Three::Exporters::ThreeJSONExporter.new.export(scene)
fixture = Three::Exporters::ThreeJSONExporter.new(deterministic_ids: true).export(scene)
json = scene.to_json
loaded_scene = Three::Loaders::ThreeJSONLoader.new.parse(json)
```

Run the full local CI-equivalent check:

```sh
bundle exec rake test
pnpm install --frozen-lockfile --ignore-scripts
pnpm audit --audit-level moderate
pnpm audit signatures
pnpm exec playwright install chromium
pnpm test:browser
```

## Documents

- [Implementation Plan](docs/implementation-plan.md)
- [Loaded Asset Traversal and Disposal Design](docs/loaded-assets-design.md)
