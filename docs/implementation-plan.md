# three.rb Implementation Plan

This document describes an implementation plan for building a Ruby 3D library inspired by three.js. The local reference repositories are:

- `~/ghq/github.com/mrdoob/three.js` at `96f057533a`
- `~/ghq/github.com/ruby/ruby.wasm` at `ef0300a`

## Recommendation

The first version should not be "three.js fully reimplemented in Ruby with a native WebGL renderer." It should be a Ruby library that lets users build a scene graph, math objects, geometry, and materials in Ruby, while delegating browser rendering to three.js through ruby.wasm.

The reason is practical. The value of three.js is not only classes like `Vector3` and `Mesh`; it also includes a large rendering runtime for WebGL/WebGPU, shader generation, texture management, loaders, XR, postprocessing, and many renderer-side systems. Rebuilding that renderer in Ruby from day one would delay any useful product milestone. A Ruby object model backed by the existing JavaScript renderer can reach "write a 3D scene in Ruby and see it in the browser" much earlier.

The recommended initial direction is:

- Build `three.rb` as a Ruby gem.
- Implement core Ruby APIs such as `Three::Vector3`, `Three::Object3D`, `Three::Scene`, `Three::Mesh`, `Three::BufferGeometry`, and `Three::Material`.
- In browser environments, use ruby.wasm's `js` bridge and delegate actual rendering to JavaScript three.js.
- Keep the renderer abstract so future backends such as `Three::Renderers::NativeOpenGLRenderer` or `Three::Renderers::ExportRenderer` can be added.
- Define the MVP as "a rotating cube written in Ruby and rendered in the browser."

## Goals

The initial goal is to let Ruby developers build and render a 3D scene with code like this:

```ruby
require "three"

scene = Three::Scene.new
camera = Three::PerspectiveCamera.new(75, aspect: 16.0 / 9.0, near: 0.1, far: 1000)
camera.position.z = 5

geometry = Three::BoxGeometry.new(1, 1, 1)
material = Three::MeshBasicMaterial.new(color: 0x00ff00)
cube = Three::Mesh.new(geometry, material)
scene.add(cube)

renderer = Three::Renderers::ThreeJSRenderer.new(canvas: "#canvas")
renderer.set_size(800, 600)

renderer.animation_loop do
  cube.rotation.x += 0.01
  cube.rotation.y += 0.01
  renderer.render(scene, camera)
end
```

Class names and concepts should remain familiar to three.js users, while method names and control flow should feel natural in Ruby. For example, `set_size` should be the primary Ruby API rather than `setSize`; three.js-style camelCase aliases can be added later as compatibility helpers where useful.

## Non-Goals

The initial version should not attempt to deliver:

- A complete Ruby implementation of a WebGL/WebGPU renderer.
- A mechanical port of every three.js class.
- Shader node systems, WebXR, physics, editor support, and postprocessing all at once.
- Native Ruby implementations of advanced loaders such as glTF, DRACO, or KTX2.
- A production-ready native desktop renderer.

These can be future extensions. Adding them too early would expand the scope before the core API has stabilized.

## Notes From Reference Repositories

### three.js

The local three.js reference has package version `0.184.0`. Its public API is assembled through `src/Three.Core.js` and `src/Three.js`, which re-export many modules.

The main module boundaries are:

- `src/math`: `Vector2`, `Vector3`, `Matrix4`, `Quaternion`, `Euler`, `Color`, and related math types.
- `src/core`: `Object3D`, `BufferGeometry`, `BufferAttribute`, `EventDispatcher`, `Raycaster`, and related core types.
- `src/objects`: `Mesh`, `Line`, `Points`, `Group`, `Sprite`, and other renderable scene objects.
- `src/scenes`: `Scene`, `Fog`, and scene-level state.
- `src/cameras`: `PerspectiveCamera`, `OrthographicCamera`, `Camera`, and related camera types.
- `src/materials`: `Material`, `MeshBasicMaterial`, `MeshStandardMaterial`, `ShaderMaterial`, and related materials.
- `src/geometries`: generated geometry classes such as `BoxGeometry`.
- `src/renderers`: `WebGLRenderer`, WebGPU support, WebXR, shaders, textures, and render state.
- `examples/jsm`: addons such as `OrbitControls`, loaders, exporters, and postprocessing.

The key architectural observation is that the renderer is much more complex than the math, object, and material layers. `WebGLRenderer` owns canvas/context handling, render lists, material programs, textures, render state, shadow maps, XR integration, and the animation loop. In three.rb, the renderer should initially be treated as a backend rather than as a direct porting target.

### ruby.wasm

ruby.wasm provides CRuby builds for WebAssembly/WASI. It includes npm packages such as `@ruby/wasm-wasi` and Ruby-version-specific packages. In the local repository, `@ruby/3.4-wasm-wasi` and `@ruby/wasm-wasi` are version `2.9.4`.

Ruby can access JavaScript through `require "js"`. This enables Ruby code to use the DOM, call JavaScript constructors, pass callbacks, and await JavaScript promises.

For three.rb, ruby.wasm is useful for:

- Running the Ruby API in the browser.
- Bridging Ruby `Three::Scene` objects to JavaScript `THREE.Scene` objects.
- Connecting to browser APIs such as `requestAnimationFrame`, canvas, DOM events, and dynamic imports.

Important constraints:

- The WASI target has limitations around threads and networking.
- Shipping a Ruby VM to the browser means initial load size and startup time must be measured.
- Frequent fine-grained Ruby-to-JavaScript calls can become overhead.
- Per-frame transfer of large vertex data from Ruby to JavaScript should be avoided.

## Architecture

three.rb should be split into layers:

```text
Ruby user code
  |
  v
Three public API
  |
  +-- Math layer
  |     Vector2 / Vector3 / Vector4 / Matrix3 / Matrix4 / Quaternion / Euler / Color
  |
  +-- Scene graph layer
  |     EventDispatcher / Object3D / Scene / Camera / Mesh / Group / Light
  |
  +-- Resource layer
  |     BufferAttribute / BufferGeometry / Texture / Material / Geometry builders
  |
  +-- Serialization and sync layer
  |     to_h / to_json / dirty tracking / backend handles
  |
  +-- Renderer abstraction
        ThreeJSRenderer / ExportRenderer / future NativeRenderer
```

### Ruby Core

The Ruby core should avoid environment-specific dependencies where possible. It should run on MRI Ruby, ruby.wasm, and ideally future Ruby runtimes.

The initial core should include:

- Math types and matrix calculations.
- `Object3D` parent/child relationships, transforms, and world matrix updates.
- Data models for geometry, materials, cameras, and lights.
- Stable IDs for JSON output and backend synchronization.
- Dispose events and dirty flags.

### Backend Abstraction

Renderers should not depend directly on `JS.global`. They should go through a backend interface.

```ruby
module Three
  module Backends
    class Base
      def materialize(object)
        raise NotImplementedError
      end

      def sync(object)
        raise NotImplementedError
      end

      def dispose(object)
        raise NotImplementedError
      end
    end
  end
end
```

The initial backend should be `Three::Backends::ThreeJS`. It creates JavaScript objects corresponding to Ruby objects and synchronizes Ruby-side changes into JavaScript.

### Synchronization Model

For the MVP, Ruby objects should be the source of truth. Each object can hold backend-specific handles.

```ruby
class Object3D
  attr_reader :backend_handles

  def mark_dirty!(field = :all)
    @dirty_fields << field
  end
end
```

Before `renderer.render(scene, camera)`, the renderer traverses the scene graph and syncs dirty objects to JavaScript. A simple full sync is acceptable in the earliest implementation, but the API should be designed around dirty tracking.

Sync granularity should include:

- Transform fields: `position`, `rotation`, `quaternion`, `scale`, `matrix`, `visible`
- Graph fields: `parent`, `children`
- Geometry fields: attributes, index, draw range, groups
- Material fields: color, opacity, transparent, wireframe, side
- Camera fields: fov, aspect, near, far, projection matrix

Geometry attributes are large. They should not be recreated on every render. On materialization, the backend should create `Float32Array`, `Uint16Array`, or `Uint32Array` objects and only resend them when the attribute changes.

## Recommended Directory Structure

```text
three.rb/
  three.rb.gemspec
  Gemfile
  Rakefile
  README.md
  lib/
    three.rb
    three/
      version.rb
      constants.rb
      math/
        vector2.rb
        vector3.rb
        vector4.rb
        matrix3.rb
        matrix4.rb
        quaternion.rb
        euler.rb
        color.rb
      core/
        event_dispatcher.rb
        object3d.rb
        buffer_attribute.rb
        buffer_geometry.rb
        clock.rb
        layers.rb
      scenes/
        scene.rb
      cameras/
        camera.rb
        perspective_camera.rb
        orthographic_camera.rb
      objects/
        group.rb
        mesh.rb
        line.rb
        points.rb
      materials/
        material.rb
        mesh_basic_material.rb
        mesh_normal_material.rb
      geometries/
        box_geometry.rb
        plane_geometry.rb
        sphere_geometry.rb
      lights/
        light.rb
        ambient_light.rb
        directional_light.rb
      renderers/
        renderer.rb
        threejs_renderer.rb
      backends/
        base.rb
        threejs.rb
      wasm/
        browser_boot.rb
  test/
    math/
    core/
    geometries/
    backends/
  examples/
    browser/
      cube/
        index.html
        main.rb
        package.json
  docs/
    implementation-plan.md
    api-design.md
    wasm-notes.md
```

## API Design Rules

### Naming

- The top-level module is `Three`.
- Class names should map to three.js concepts, for example `Three::Vector3`, `Three::Mesh`, and `Three::Scene`.
- Public Ruby methods should use `snake_case`.
- camelCase aliases such as `setSize` can be added later for three.js users.
- Mutating operations should follow three.js behavior: `vector.add(other)` mutates `self` and returns `self`.
- Ruby-friendly non-mutating operators such as `vector + other` may also be provided.

### Initial Public API

The first stable API surface should include:

```ruby
Three::Vector3.new(x = 0, y = 0, z = 0)
Three::Vector3#set(x, y, z)
Three::Vector3#copy(other)
Three::Vector3#clone
Three::Vector3#add(other)
Three::Vector3#sub(other)
Three::Vector3#multiply_scalar(value)
Three::Vector3#normalize
Three::Vector3#length

Three::Object3D#add(child)
Three::Object3D#remove(child)
Three::Object3D#traverse { |object| ... }
Three::Object3D#update_matrix
Three::Object3D#update_matrix_world(force = false)

Three::Scene.new
Three::PerspectiveCamera.new(fov = 50, aspect: 1, near: 0.1, far: 2000)
Three::Mesh.new(geometry = Three::BufferGeometry.new, material = Three::MeshBasicMaterial.new)
Three::BoxGeometry.new(width = 1, height = 1, depth = 1)
Three::MeshBasicMaterial.new(color: 0xffffff, wireframe: false)
Three::Renderers::ThreeJSRenderer.new(canvas:)
Three::Renderers::ThreeJSRenderer#render(scene, camera)
Three::Renderers::ThreeJSRenderer#animation_loop { |time| ... }
```

### Options Hashes

three.js constructor parameter objects should become Ruby keyword arguments.

```ruby
Three::MeshBasicMaterial.new(color: 0xffcc00, transparent: true, opacity: 0.5)
```

Internally, classes may still keep a `parameters` hash to support later JSON reconstruction.

### Events

The equivalent of three.js `EventDispatcher` should use Ruby blocks.

```ruby
mesh.on(:dispose) { |event| puts event.type }
mesh.dispatch_event(:dispose)
```

## Implementation Phases

### Phase 0: Gem Foundation

The goal is to create a Ruby project structure that can support continued development.

Tasks:

- Add `three.rb.gemspec`.
- Add `lib/three.rb` and `lib/three/version.rb`.
- Choose a test runner. `minitest` is sufficient initially.
- Make `bundle exec rake test` work.
- Avoid making `rubocop` too strict at the start; use minimal linting if needed.
- Add quick start and development commands to the README.

Completion criteria:

- Tests can run after `bundle install`.
- `require "three"` works as a gem entrypoint.
- The project layout is ready for CI.

### Phase 1: Math Layer

The math layer is valuable even without a renderer and is the foundation for the rest of the library.

Implementation targets:

- `Vector2`
- `Vector3`
- `Vector4`
- `Euler`
- `Quaternion`
- `Matrix3`
- `Matrix4`
- `Color`
- `MathUtils`

Priority:

1. `Vector3`
2. `Matrix4`
3. `Quaternion`
4. `Euler`
5. `Color`

Important details:

- Use the same column-major matrix representation as three.js.
- Use epsilon comparisons for floating-point tests.
- Design `Euler` and `Quaternion` with change callbacks so `Object3D#rotation` and `Object3D#quaternion` can stay synchronized.
- `Color` should accept values like `0xff00aa`, `"#ff00aa"`, and RGB floats.

Tests:

- Unit tests for math operations.
- `clone` and `copy` return or update distinct objects correctly.
- Matrix compose/decompose round trips.
- Quaternion/Euler round trips.
- A small set of fixtures matching known three.js results.

### Phase 2: Core Scene Graph

The goal is to implement object hierarchy and transform updates.

Implementation targets:

- `EventDispatcher`
- `Object3D`
- `Group`
- `Scene`
- `Camera`
- `PerspectiveCamera`
- `OrthographicCamera`
- `Clock`
- `Layers`

Major `Object3D` properties:

- `id`
- `uuid`
- `name`
- `type`
- `parent`
- `children`
- `position`
- `rotation`
- `quaternion`
- `scale`
- `matrix`
- `matrix_world`
- `matrix_auto_update`
- `matrix_world_auto_update`
- `matrix_world_needs_update`
- `visible`
- `user_data`

Major methods:

- `add`
- `remove`
- `remove_from_parent`
- `clear`
- `traverse`
- `traverse_visible`
- `get_object_by_name`
- `update_matrix`
- `update_matrix_world`
- `look_at`
- `to_h`

Completion criteria:

- A scene can contain meshes, groups, and cameras.
- Parent/child transforms are reflected in world matrices.
- Updating `rotation` also updates `quaternion`.
- Updating `quaternion` also updates `rotation`.

### Phase 3: Geometry and Materials

The goal is to create renderable objects that can be passed to a backend.

Implementation targets:

- `BufferAttribute`
- `Float32BufferAttribute`
- `Uint16BufferAttribute`
- `Uint32BufferAttribute`
- `BufferGeometry`
- `BoxGeometry`
- `PlaneGeometry`
- `SphereGeometry`
- `Material`
- `MeshBasicMaterial`
- `MeshNormalMaterial`
- `Mesh`
- `Line`
- `Points`

Initial `BufferGeometry` methods:

- `set_index`
- `get_index`
- `set_attribute`
- `get_attribute`
- `delete_attribute`
- `add_group`
- `clear_groups`
- `set_draw_range`
- `compute_bounding_box`
- `compute_bounding_sphere`
- `to_h`

For the first version, geometry data can be stored as Ruby `Array<Numeric>`. However, attributes should carry a `component_type` so the bridge can convert them to JavaScript TypedArrays.

Completion criteria:

- `BoxGeometry` generates position, normal, uv, and index data.
- `MeshBasicMaterial` supports color, wireframe, and opacity.
- A `Mesh` with geometry and material can be added to a scene.

### Phase 4: Browser Renderer MVP

The goal is to render a Ruby-authored scene in the browser.

Current implementation status:

- `Three::Backends::ThreeJS` exists with an injectable adapter boundary.
- `Three::Renderers::ThreeJSRenderer` exists and delegates renderer creation, sizing, animation loops, scene syncing, and render calls to the backend.
- The bridge can materialize `Scene`, `Group`, `Object3D`, `PerspectiveCamera`, `OrthographicCamera`, `Mesh`, `AmbientLight`, `DirectionalLight`, `PointLight`, `Texture`, `BoxGeometry`, `PlaneGeometry`, `SphereGeometry`, generic `BufferGeometry`, `BufferAttribute`, `MeshBasicMaterial`, `MeshLambertMaterial`, `MeshStandardMaterial`, and `MeshNormalMaterial`.
- Unit tests cover materialization, handle caching, transform syncing, rendering delegation, and disposal through a fake three.js adapter.
- `examples/browser/cube` loads pnpm-managed ruby.wasm and three.js browser packages, loads this library from `lib/`, and renders a rotating cube through `Three::Renderers::ThreeJSRenderer`.
- `examples/browser/cube/smoke_test.mjs` provides an opt-in Playwright smoke test that serves the repository root, waits for the example to reach `Running`, and samples the WebGL canvas for nonblank pixels.
- `examples/browser/composition` renders an `OrthographicCamera` view with ambient/directional/point lights, `PlaneGeometry`, `SphereGeometry`, grouped meshes, `TextureLoader` repeat/wrap/filter settings, `MeshLambertMaterial`, `MeshStandardMaterial`, `MeshNormalMaterial`, and a material color update through the same renderer path.
- The browser bridge exposes the three.js `OrbitControls` addon through `Three::Controls::OrbitControls`.
- Browser examples share common ruby.wasm boot and Playwright smoke-test helpers under `examples/browser/shared`.
- CI runs the Ruby unit tests and Playwright browser smoke tests with pnpm-managed browser dependencies.
- Core scene, material, and geometry objects expose dirty state, and the Three.js backend skips clean transform, material, geometry, and child-list sync work.
- The next implementation step is adding a dedicated textured browser example or expanding the remaining light coverage.

Recommended structure:

- `examples/browser/cube/index.html`
- `examples/browser/cube/main.rb`
- A JavaScript boot script starts the ruby.wasm VM.
- JavaScript imports three.js and exposes either `globalThis.THREE` or an explicit module handle to Ruby.
- `Three::Renderers::ThreeJSRenderer` uses `JS.global[:THREE]` to create JavaScript objects.

Initial bridge responsibilities:

- Ruby `Scene` -> JS `THREE.Scene`
- Ruby `PerspectiveCamera` -> JS `THREE.PerspectiveCamera`
- Ruby `OrthographicCamera` -> JS `THREE.OrthographicCamera`
- Ruby `AmbientLight` -> JS `THREE.AmbientLight`
- Ruby `DirectionalLight` -> JS `THREE.DirectionalLight`
- Ruby `BoxGeometry` -> JS `THREE.BufferGeometry` or JS `THREE.BoxGeometry`
- Ruby `MeshBasicMaterial` -> JS `THREE.MeshBasicMaterial`
- Ruby `MeshLambertMaterial` -> JS `THREE.MeshLambertMaterial`
- Ruby `Texture` -> JS `THREE.TextureLoader.load(...)`
- Ruby `Mesh` -> JS `THREE.Mesh`
- Ruby `OrbitControls` -> JS addon `OrbitControls`
- Ruby `Object3D` transform -> JS object transform
- `animation_loop` -> `requestAnimationFrame`

For early built-in geometries such as `BoxGeometry`, it is acceptable to directly create JS `THREE.BoxGeometry`. Still, design a `BufferGeometry` materialization path so Ruby-generated geometry can later be sent to JS as buffers.

Completion criteria:

- A cube appears in the browser.
- Ruby code can update the cube's rotation.
- Canvas resizing works.
- `dispose` releases JS geometry/material resources.

### Phase 5: Serialization and Export

The goal is to make three.rb scenes useful beyond immediate rendering.

Implementation targets:

- `Object3D#to_h`
- `Object3D#to_json`
- `Geometry#to_h`
- `Material#to_h`
- `Three::Exporters::ThreeJSONExporter`

Use cases:

- Build a scene on a Ruby server and send it to a browser as JSON.
- Save scene artifacts even when no native renderer is available.
- Use deterministic JSON fixtures for regression tests.

Completion criteria:

- A simple scene can be exported to JSON.
- A minimal loader can reconstruct a scene from JSON.
- Equivalent scenes produce deterministic JSON.

### Phase 6: Interaction and Controls

The goal is to support interactive browser experiences.

Initially, wrap JavaScript `OrbitControls` instead of rewriting it in Ruby.

Implementation targets:

- `Three::Controls::OrbitControls`
- Pointer, wheel, and key event bridges.
- Camera update integration with the render loop.

Completion criteria:

- Ruby code can call `OrbitControls.new(camera, renderer.dom_element)`.
- Mouse drag and wheel zoom work.

### Phase 7: Asset Loading

The goal is to handle external assets needed for practical scenes.

Initial loaders should delegate to JavaScript loaders.

Loader priority:

1. `TextureLoader`
2. `GLTFLoader`
3. `CubeTextureLoader`

Ruby API:

```ruby
loader = Three::Loaders::GLTFLoader.new
loader.load("model.glb") do |gltf|
  scene.add(gltf.scene)
end
```

Important details:

- Do not depend on ruby.wasm networking for asset loading; let JavaScript `fetch` and three.js loaders handle it.
- Avoid loading binary assets into Ruby when a JavaScript loader result can be wrapped.

Completion criteria:

- Textures can be assigned to materials.
- glTF models can be added to a scene.

### Phase 8: Renderer Maturity

The goal is to move from a wrapper into a practical 3D library.

Candidates:

- Lights: `AmbientLight`, `DirectionalLight`, `PointLight`
- Materials: `MeshLambertMaterial`, `MeshPhongMaterial`, `MeshStandardMaterial`
- Textures: wrapping, filtering, color space
- Render targets
- Shadows
- Instancing
- Raycaster
- Postprocessing wrappers
- WebGPU renderer wrapper

Completion criteria:

- A basic lighting scene works.
- Material and texture disposal does not leak resources.
- Synchronizing around 1000 meshes remains interactive.

### Phase 9: Native Renderer Evaluation

Only after the earlier phases should a Ruby-native renderer be evaluated.

Options:

- OpenGL + GLFW backend
- Vulkan wrapper
- SDL + OpenGL
- Server-side software renderer
- Choosing glTF export as the non-browser path

If a native renderer is added, the public API should stay aligned with the existing core. Only the renderer backend should change.

## ruby.wasm Adoption Decision

ruby.wasm fits this use case, but its role should be limited.

Good uses:

- Writing browser scenes in Ruby.
- Connecting a Ruby object model to the JavaScript three.js renderer.
- Writing event handlers and animation loops as Ruby blocks.
- Shipping interactive browser examples.

Poor uses:

- Calling low-level WebGL APIs from Ruby at high frequency.
- Updating large vertex buffers across the Ruby/JavaScript boundary every frame.
- Implementing network- or thread-heavy loaders entirely in Ruby.
- Pages where the startup size of a Ruby VM is unacceptable.

Therefore, three.rb should adopt ruby.wasm as the browser runtime while keeping hot paths in JavaScript three.js.

## Performance Strategy

Do not over-optimize before the API exists, but avoid structural mistakes.

- Do not recreate all JS objects every render.
- Do not convert geometry attributes into TypedArrays every render.
- Avoid large numbers of tiny Ruby-to-JavaScript property calls.
- Use dirty flags and sync only changed objects.
- Do not immediately reflect `position.x = ...` to JS; batch transform updates before rendering.
- Require explicit `needs_update!` calls for large geometry changes.

Initial benchmarks:

- 1 cube animation
- 100 cubes with transform sync
- 1000 cubes with transform sync
- 1 mesh with 100k vertices
- 10 textures
- 1 glTF model

## Test Plan

### Ruby Unit Tests

Targets:

- Math operations
- Matrix compose/decompose
- Scene graph add/remove
- `Object3D` traversal
- Camera projection
- Geometry generation
- Material options
- JSON serialization

### Golden Tests

Create a small set of fixtures that match known three.js outputs.

Examples:

- Vertex and index counts for `BoxGeometry.new(1, 1, 1)`.
- Projection matrix for `PerspectiveCamera.new(75, aspect: 2)`.
- Result of `Vector3.new(1, 2, 3).normalize`.

Use epsilon comparisons instead of exact equality for floating-point values.

### Browser Smoke Tests

Use Playwright or a similar tool to open the browser example and verify:

- A canvas exists.
- A WebGL context is created.
- The first frame draws non-empty pixels.
- Pixels change after the animation loop advances.

### ruby.wasm Smoke Tests

Targets:

- The Ruby VM starts.
- `require "three"` works.
- `require "js"` works.
- Ruby can create a JS `THREE.Scene`.
- A Ruby callback can be called from `requestAnimationFrame`.

## License Strategy

This project is MIT licensed. three.js is also MIT licensed, but the project should follow these rules:

- If specific three.js code is ported, record the source file.
- Preserve required copyright and MIT license notices.
- Prefer using three.js API behavior as a reference while writing Ruby implementations, instead of copying code verbatim.
- If large assets such as shader chunks are imported, document them in `NOTICE` or project docs.

## Risks and Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| A native renderer delays the MVP | High | Limit Phase 4 to the JS three.js backend |
| Ruby/JavaScript boundary overhead is too high | Medium | Design around dirty sync and batched conversion |
| ruby.wasm startup size is large | Medium | Measure in examples; evaluate CDN, cache, and lazy loading |
| The project chases full three.js compatibility too early | Medium | Limit the initial API to the cube demo subset |
| Ruby style conflicts with three.js compatibility | Medium | Make snake_case primary and keep camelCase in a compatibility layer |
| Geometry storage becomes hard to optimize later | Medium | Give `BufferAttribute` component types and update ranges early |
| Loaders become too complex | Medium | Wrap JS loaders initially |
| License attribution is missed | High | Track source files in docs and file headers when porting code |

## MVP Definition

The MVP is complete when:

- `require "three"` works.
- Ruby can create scenes, cameras, meshes, materials, and geometry.
- A browser example starts ruby.wasm.
- A Ruby-authored cube scene renders through the JS three.js backend.
- Cube rotation animation is written as a Ruby block.
- Ruby unit tests and a browser smoke test exist.
- The README includes usage instructions.

## First 10 Tasks

- [x] Add `three.rb.gemspec`, `Gemfile`, `Rakefile`, and `lib/three.rb`.
- [x] Add `Three::Version` and the module skeleton.
- [x] Implement `Vector3`, `Matrix4`, `Quaternion`, `Euler`, and `Color`.
- [x] Add math unit tests.
- [x] Implement `EventDispatcher` and `Object3D`.
- [x] Implement `Scene`, `Camera`, `PerspectiveCamera`, and `Group`.
- [x] Implement `BufferAttribute`, `BufferGeometry`, and `BoxGeometry`.
- [x] Implement `Material`, `MeshBasicMaterial`, and `Mesh`.
- [x] Add skeletons for `Three::Backends::ThreeJS` and `ThreeJSRenderer`.
- [x] Build `examples/browser/cube` and render a cube with ruby.wasm + three.js.

## Next Tasks

1. Add a dedicated textured browser example once texture assignment needs more coverage.
2. Add `HemisphereLight` so PBR materials have broader ambient lighting coverage.
3. Keep reviewing low-risk dependency updates after checking their CI results.

## Decisions Still Open

Before implementation begins, decide:

- Whether to start with `minitest` or `rspec`.
- Browser examples should use pnpm-managed local browser dependencies for ruby.wasm and three.js, avoiding CDN runtime drift and browser ORB failures.
- Whether camelCase aliases should exist from the first release or be added later.
- Whether geometry arrays should use `numo-narray` or start with standard `Array`.
- Whether the published gem name should be `three.rb`, `three-rb`, or `three`.

Current recommendation: use `minitest`, pnpm-managed browser dependencies, defer camelCase aliases, start with standard `Array`, and publish as `three.rb`.
