# three.rb
Ruby 3D Library.

## Status

This project is in the initial implementation phase. The current code covers the gem foundation, math primitives, scene graph basics, and initial geometry/material objects.

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
