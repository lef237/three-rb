# three-rb

Ruby 3D Library.

Published to RubyGems as `three-rb`; require it in Ruby as `three`.

## Status

This project is in browser-first alpha. The current code covers the gem foundation, math primitives, scene graph basics, geometry/material objects, dirty-tracked backend sync, JSON export/load, browser examples, and a three.js backend/renderer bridge through ruby.wasm.

## Browser-first alpha scope

Supported scope for the first public release:

- Pure Ruby scene construction, math, cameras, lights, geometry, materials, textures, layers, raycasting helpers, and JSON export/load.
- Browser rendering through `Three::Renderers::ThreeJSRenderer`, ruby.wasm, and pnpm-managed `three@0.184.0`.
- JavaScript-delegated browser features for texture loading, cube/RGBE textures, glTF/DRACO loading, OrbitControls, animation mixers, instancing, picking, shadows, and an initial postprocessing pipeline.

Out of scope for the first public release:

- A Ruby-native OpenGL/Vulkan/software renderer.
- Full three.js API compatibility.
- Stable APIs for every addon loader, render target, postprocessing pass, WebGPU, or XR workflow.

## Installation

Install the released gem from RubyGems:

```sh
gem install three-rb
```

Or add it to a Gemfile:

```ruby
gem "three-rb", "~> 0.1"
```

Browser rendering examples also need `pnpm`, because ruby.wasm, three.js, and three.js addons are installed from `package.json`.

## Quick Start

three-rb is browser-first. The fastest way to try the released gem is to unpack a writable copy of the gem and run one of the included browser examples:

```sh
gem install three-rb
mkdir hello-three-rb
cd hello-three-rb
gem unpack three-rb
cd three-rb-*/
pnpm install
ruby -run -e httpd . -p 8000
```

```text
http://localhost:8000/examples/browser/ruby/
```

This page runs the Ruby entrypoint at `examples/browser/ruby/main.rb` through ruby.wasm and renders a transparent red gemstone and extruded `three-rb` title with three.js. Use `http://localhost:8000/...`; do not open the files with `file://`, because the browser runtime loads ES modules, wasm, and assets over HTTP.

After the ruby example works, inspect `examples/browser/ruby/main.rb` to see the Ruby scene code. For the smallest possible browser scene, see `examples/browser/cube/main.rb`. For a standalone app directory with your own Ruby entrypoint, see [Standalone Browser App](docs/standalone-browser-app.md).

## Plain Ruby Check

If you only want to confirm the Ruby API loads without browser rendering, create `hello_three.rb`:

```ruby
require "three"

puts "three-rb #{Three::VERSION}"

scene = Three::Scene.new
camera = Three::PerspectiveCamera.new(75, aspect: 16.0 / 9.0)
camera.position.z = 5

geometry = Three::BoxGeometry.new(1, 1, 1)
material = Three::MeshBasicMaterial.new(color: 0x00ff00)
cube = Three::Mesh.new(geometry, material)

scene.add(cube)

puts scene.class
puts cube.class
```

Run it:

```sh
ruby hello_three.rb
```

You should see the library load and create Ruby scene objects:

```text
three-rb 0.1.0
Three::Scene
Three::Mesh
```

Browser rendering is available through `Three::Renderers::ThreeJSRenderer`, which targets three.js from ruby.wasm.

## Browser Examples In This Repository

When developing this repository, install browser dependencies, serve the repository root, and open one of the browser examples:

```sh
pnpm install
ruby -run -e httpd . -p 8000
```

```text
http://localhost:8000/examples/browser/ruby/
http://localhost:8000/examples/browser/cube/
http://localhost:8000/examples/browser/composition/
http://localhost:8000/examples/browser/textures/
http://localhost:8000/examples/browser/cubemap/
http://localhost:8000/examples/browser/gltf/
http://localhost:8000/examples/browser/serialization/
http://localhost:8000/examples/browser/picking/
http://localhost:8000/examples/browser/primitives/
http://localhost:8000/examples/browser/postprocessing/
```

See [Browser Examples](examples/browser/README.md) for the feature coverage map and per-example smoke commands. See [Browser Runtime](docs/browser-runtime.md) for the current embedding and boot contract.

The examples load pnpm-managed browser packages from `node_modules/`: `@ruby/3.4-wasm-wasi@2.9.4-2026-05-11-a`, `@ruby/wasm-wasi@2.9.4-2026-05-11-a`, and `three@0.184.0`.

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

Build and install the gem into a temporary `GEM_HOME`, then run the install smoke test:

```sh
bundle exec rake release:gem_smoke
```

Export a Ruby-authored scene to a deterministic JSON-friendly hash:

```ruby
exported = Three::Exporters::ThreeJSONExporter.new.export(scene)
fixture = Three::Exporters::ThreeJSONExporter.new(deterministic_ids: true).export(scene)
json = scene.to_json
loaded_scene = Three::Loaders::ThreeJSONLoader.new.parse(json)
```

Run the local release preflight check:

```sh
pnpm install
pnpm exec playwright install chromium
bundle exec rake release:preflight
```

Run the full local CI-equivalent check, including dependency audits:

```sh
pnpm install --frozen-lockfile --ignore-scripts
pnpm audit --audit-level moderate
pnpm audit signatures
pnpm exec playwright install chromium
bundle exec rake release:preflight
```

## Documents

- [Implementation Plan](docs/implementation-plan.md)
- [Next Work](docs/next-work.md)
- [Browser Runtime](docs/browser-runtime.md)
- [Browser Examples](examples/browser/README.md)
- [Standalone Browser App](docs/standalone-browser-app.md)
- [Loaded Asset Traversal and Disposal Design](docs/loaded-assets-design.md)
- [Release Readiness](docs/release-readiness.md)
- [Publishing](docs/publishing.md)
