# three.rb
Ruby 3D Library.

## Status

This project is in the initial implementation phase. The current code covers the gem foundation, math primitives, scene graph basics, initial geometry/material objects, and the first three.js backend/renderer bridge skeleton.

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

Serve the repository root and open the cube example:

```sh
ruby -run -e httpd . -p 8000
```

```text
http://localhost:8000/examples/browser/cube/
```

The example loads `@ruby/3.4-wasm-wasi@2.9.4` and `three@0.184.0` in the browser.

## Development

Install dependencies:

```sh
bundle install
```

Run tests:

```sh
bundle exec rake test
```

## Documents

- [Implementation Plan](docs/implementation-plan.md)
