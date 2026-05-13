# Loaded Asset Traversal and Disposal Design

This document records the recommended design for loaded assets such as glTF scenes. It is intended to be self-contained enough to resume implementation even if the conversation context is lost.

## Status Snapshot

Repository state when this decision was written:

- Branch: `main`
- Relevant recent commits:
  - `421a89c Add GLTF loader`
  - `3bc389d Add CubeTexture loader`
  - `9b6307c Add renderer disposal helper`
- Current implementation:
  - `Three::Loaders::GLTFLoader` delegates to JavaScript `GLTFLoader#loadAsync`.
  - `Three::Loaders::GLTF#scene` is a `Three::ExternalObject3D`.
  - `Three::ExternalObject3D` stores a loaded JavaScript `Object3D` handle.
  - `Three::Backends::ThreeJS#materialize` returns that handle directly for `ExternalObject3D`.
  - `examples/browser/gltf` verifies that a loaded glTF scene can be added to a Ruby-authored scene and rendered.

Important local files:

- `lib/three/loaders/gltf_loader.rb`
- `lib/three/objects/external_object3d.rb`
- `lib/three/backends/threejs.rb`
- `examples/browser/gltf/main.rb`
- `examples/browser/gltf/smoke_test.mjs`
- `test/three/loaders/gltf_loader_test.rb`
- `test/three/objects/external_object3d_test.rb`
- `test/three/backends/threejs_test.rb`

## Implementation Status

The recommended design has been implemented for the current loaded-asset MVP:

- `ExternalObject3D#add`, `#remove`, and `#clear` now reject Ruby child mutation.
- `Three::Backends::ThreeJS#traverse_handles` traverses backend object handles without changing `Object3D#traverse`.
- `Three::Renderers::ThreeJSRenderer#traverse_handles` exposes the same traversal at renderer scope.
- `Three::Backends::ThreeJS#dispose_subtree` delegates subtree cleanup to the backend adapter.
- `Three::Renderers::ThreeJSRenderer#dispose_subtree` provides high-level loaded-asset cleanup and defaults `dispose_textures` to `true`.
- `RubyWasmAdapter` collects unique geometries, materials, common material texture slots, scene background/environment textures, and skeletons before disposing.
- `FakeThreeJSAdapter` mirrors this behavior for unit tests.
- `examples/browser/gltf/smoke_test.mjs` verifies that the Ruby renderer API detaches a loaded glTF root and dispatches geometry/material/texture dispose events.

Remaining work:

- The Ruby material model exposes common `MeshStandardMaterial` PBR texture slots and `MeshPhysicalMaterial` physical texture slots, including anisotropy and clearcoat maps. Broaden ownership helpers further if additional material classes introduce new texture slots.
- If future APIs need to inspect or edit loaded child objects, design explicit wrapper types instead of changing `Object3D#traverse`.

## Decision

Keep loaded three.js assets opaque by default.

Do not fully convert a loaded glTF scene into Ruby `Mesh`, `Material`, `BufferGeometry`, `Texture`, `Camera`, or animation objects at this stage. Instead:

1. Use `ExternalObject3D` as an opaque root wrapper around the loaded JavaScript `Object3D`.
2. Let Ruby own only the attachment point and transform-level concerns for that external root.
3. Add explicit backend/renderer helpers for traversing and disposing resources inside the external JavaScript subtree.
4. Preserve the existing pure Ruby `Object3D#traverse` semantics for Ruby-authored objects.

The first target user-facing API should be:

```ruby
gltf = Three::Loaders::GLTFLoader.new.load("/models/model.gltf")
scene.add(gltf.scene)

# Later, when the loaded asset is no longer needed:
renderer.dispose_subtree(gltf.scene, remove: true, dispose_textures: true)
```

## Rationale

three.js `GLTFLoader` already constructs a complete JavaScript scene graph. Its documented usage is to load a glTF asset and add `gltf.scene` directly to the scene. The returned object also carries `animations`, `scenes`, `cameras`, `asset`, `parser`, and `userData`.

`GLTFLoader` performs non-trivial work that should not be duplicated in Ruby early:

- It returns `Group` scenes, not `THREE.Scene` instances.
- It handles shared node references and clones reused nodes when necessary.
- It reuses non-scene resources such as materials, geometries, and textures by reference.
- It preserves parser associations and glTF extension data.
- It can involve skins, skeletons, morph targets, animations, compressed geometry, texture transforms, and custom extensions.

Ruby-side full conversion would either lose these semantics or force a large, fragile mirror of three.js loader internals. That is not justified for the current goal: write Ruby scene code and render through three.js in the browser.

## Source Findings

These findings were verified against the local vendored/reference repositories.

three.js facts:

- `Object3D#add` removes an object from its previous parent and attaches it to the new parent.
- `Object3D#traverse` walks JavaScript children depth-first and discourages modifying the scene graph inside the callback.
- `BufferGeometry#dispose`, `Material#dispose`, and `Texture#dispose` dispatch disposal events for GPU-related resources.
- Removing a mesh from a scene does not dispose its geometry or material.
- Disposing a material does not dispose textures, because textures can be shared.
- The three.js manual recommends explicit resource tracking for cleanup.
- Scene-related resources such as `scene.background`, `scene.environment`, and `material.envMap` may leave renderer-internal resources visible in `renderer.info.memory`, even after reachable app resources are disposed.

Local source locations:

- `node_modules/three/src/core/Object3D.js`
- `node_modules/three/src/core/BufferGeometry.js`
- `node_modules/three/src/materials/Material.js`
- `node_modules/three/src/textures/Texture.js`
- `node_modules/three/examples/jsm/loaders/GLTFLoader.js`
- `node_modules/three/examples/jsm/utils/SkeletonUtils.js`
- `~/ghq/github.com/mrdoob/three.js/manual/en/how-to-dispose-of-objects.html`
- `~/ghq/github.com/mrdoob/three.js/manual/en/cleanup.html`

ruby.wasm facts:

- `JS::Object#await` works in `evalAsync` / `callAsync` contexts.
- `JS::Object` supports property access with `object[:name]`, method calls with `call`, and array conversion with `to_a`.
- Passing blocks/procs to JavaScript callbacks is supported enough for traversal-style APIs.

Local source locations:

- `~/ghq/github.com/ruby/ruby.wasm/packages/gems/js/lib/js.rb`
- `~/ghq/github.com/ruby/ruby.wasm/packages/npm-packages/ruby-wasm-wasi/test/eval_async.test.js`

## Verified Behavior

The existing glTF browser smoke test verifies:

- `Three::Loaders::GLTFLoader` loads `examples/browser/assets/triangle.gltf`.
- The returned `gltf.scene` can be added to a Ruby `Scene`.
- The loaded JavaScript scene renders through `Three::Renderers::ThreeJSRenderer`.
- The animation loop can mutate the external root transform.

Additional manual verification was performed in a real headless browser:

```text
objects=2
meshes=1
geometries=1
materials=1
textures=0
geometryDisposeEvents=1
materialDisposeEvents=1
textureDisposeEvents=0
```

This confirmed that a loaded glTF JavaScript subtree can be traversed through its handle and that geometry/material disposal events fire as expected.

## Recommended API Shape

### External Object Traversal

Keep Ruby-authored traversal and JavaScript-loaded traversal separate.

Recommended:

```ruby
gltf.scene.traverse_handles do |handle|
  # handle is a JS object in ruby.wasm, or an adapter-provided object in tests.
end
```

or renderer/backend scoped:

```ruby
renderer.traverse_handles(gltf.scene) do |handle|
  # inspect loaded JS Object3D handles
end
```

Do not make `Object3D#traverse` silently enter the JavaScript subtree. That method currently traverses Ruby-owned `Object3D` instances and should remain predictable on MRI Ruby and ruby.wasm.

### External Object Mutability

Guard `ExternalObject3D#add`, `#remove`, and `#clear` for now.

Reason: the backend currently syncs Ruby child-list changes by clearing and re-adding children on the JavaScript handle. If a user adds Ruby children under an `ExternalObject3D`, a later sync can wipe the loaded glTF children. Until mixed Ruby/loaded children are explicitly designed, this should fail loudly.

Recommended behavior:

```ruby
class Three::ExternalObject3D
  def add(*)
    raise NotImplementedError, "ExternalObject3D does not support Ruby child mutation yet"
  end

  def remove(*)
    raise NotImplementedError, "ExternalObject3D does not support Ruby child mutation yet"
  end

  def clear
    raise NotImplementedError, "ExternalObject3D does not support Ruby child mutation yet"
  end
end
```

Transform properties should continue to work:

```ruby
gltf.scene.position.y = 1
gltf.scene.scale.set(2, 2, 2)
```

### Resource Disposal

Add `dispose_subtree` to renderer/backend instead of putting disposal directly on `GLTF`.

Recommended renderer API:

```ruby
renderer.dispose_subtree(
  gltf.scene,
  remove: true,
  dispose_geometries: true,
  dispose_materials: true,
  dispose_textures: true,
  dispose_skeletons: true
)
```

Default recommendation:

- `remove: true`
- `dispose_geometries: true`
- `dispose_materials: true`
- `dispose_textures: false` at the lowest backend layer
- `dispose_textures: true` for high-level loaded-asset cleanup helpers
- `dispose_skeletons: true`, but de-duplicate skeletons

Texture disposal must be explicit because textures can be shared. High-level asset cleanup may opt into it because it is normally called when unloading the whole asset.

### Resource Collection

Disposal should collect unique resources before disposing:

- Object roots:
  - optionally remove root from parent
- Geometries:
  - `object.geometry`
- Materials:
  - `object.material`
  - arrays of materials
- Textures:
  - common material slots:
    - `map`
    - `normalMap`
    - `roughnessMap`
    - `metalnessMap`
    - `aoMap`
    - `emissiveMap`
    - `alphaMap`
    - `bumpMap`
    - `displacementMap`
    - `envMap`
    - `lightMap`
    - `specularMap`
    - `anisotropyMap`
    - `clearcoatMap`
    - `clearcoatNormalMap`
    - `clearcoatRoughnessMap`
    - `transmissionMap`
    - `thicknessMap`
    - `iridescenceMap`
    - `iridescenceThicknessMap`
    - `sheenColorMap`
    - `sheenRoughnessMap`
    - `specularColorMap`
    - `specularIntensityMap`
- Skeletons:
  - `object.skeleton`
- Scene resources when disposing a `Scene` or when explicitly requested:
  - `scene.background`
  - `scene.environment`

Do not rely on `renderer.info.memory` reaching zero as a strict assertion. three.js may keep internal resources for backgrounds, environments, and other renderer internals.

## Backend Boundary

Prefer implementing loaded-asset traversal/disposal behind adapter methods:

```ruby
def dispose_subtree(object, **options)
  handle = materialize(object)
  @adapter.dispose_object3d_subtree(handle, **options)
  @handles.delete(object.uuid) if object.respond_to?(:uuid)
  handle
end
```

Adapter responsibilities:

- RubyWasmAdapter:
  - use JavaScript `Object3D#traverse`
  - collect JS `Set`s of resources
  - call `parent.remove(object)` when `remove: true`
  - call `dispose()` on collected resources
- FakeThreeJSAdapter:
  - provide equivalent behavior for hash handles
  - record calls for unit tests

This keeps browser-specific JavaScript traversal out of the pure Ruby object model.

## Rejected Alternatives

### Full Ruby Conversion of glTF

Rejected for now.

Why:

- It would require mirroring too many three.js loader semantics.
- It risks breaking shared references, skins, animations, extension metadata, and parser associations.
- It increases maintenance burden without improving the current browser-first MVP.

### Make `ExternalObject3D#traverse` Enter the JS Subtree

Rejected for now.

Why:

- It changes the meaning of existing Ruby traversal.
- It makes behavior runtime-dependent: MRI Ruby cannot traverse JS handles.
- It hides expensive JS bridge calls behind a familiar pure Ruby method.

### Dispose Everything Automatically on Remove

Rejected.

Why:

- three.js explicitly separates removal from disposal.
- Geometry, material, texture, and skeleton resources can be shared.
- Automatic disposal would surprise users and could break reused assets.

## Implementation Plan

1. Guard `ExternalObject3D#add`, `#remove`, and `#clear`.
2. Add backend adapter support for traversing an external JS `Object3D` handle.
3. Add resource collection in `RubyWasmAdapter`.
4. Add `Three::Backends::ThreeJS#dispose_subtree`.
5. Add `Three::Renderers::ThreeJSRenderer#dispose_subtree`.
6. Add unit tests with `FakeThreeJSAdapter`.
7. Add browser smoke coverage to `examples/browser/gltf/smoke_test.mjs`:
   - attach disposal listeners to loaded geometry/material
   - call `renderer.dispose_subtree(gltf.scene, remove: true, dispose_textures: true)`
   - assert geometry/material dispose events fired
   - assert root was removed from parent
8. Update `docs/implementation-plan.md` current status and next tasks.

## Suggested First Patch

Implement only the guard first:

```ruby
class Three::ExternalObject3D < Object3D
  def add(*)
    raise NotImplementedError, "ExternalObject3D does not support Ruby child mutation yet"
  end

  def remove(*)
    raise NotImplementedError, "ExternalObject3D does not support Ruby child mutation yet"
  end

  def clear
    raise NotImplementedError, "ExternalObject3D does not support Ruby child mutation yet"
  end
end
```

Tests:

```sh
ruby -Itest test/three/objects/external_object3d_test.rb
bundle exec rake test
pnpm test:browser:gltf
```

## Validation Commands

After implementing traversal/disposal helpers, run:

```sh
bundle exec rake test
pnpm test:browser
pnpm audit --audit-level moderate
pnpm audit signatures
gem build three.rb.gemspec --output /private/tmp/three.rb-check.gem
git diff --check
```

If the browser smoke tests fail with a local server sandbox error, rerun the same pnpm command with the approved escalated prefix.

## Resume Checklist

If work resumes from this document alone:

1. Read the status snapshot and decision sections above before editing code.
2. Confirm the repository state with `git status --short --branch`.
3. Start with the implementation plan in order unless the current code already includes some steps.
4. Keep `Object3D#traverse` Ruby-only.
5. Keep loaded glTF internals opaque unless a later design explicitly changes that.
6. Add disposal behavior behind backend/adapter APIs, not directly inside the pure Ruby object graph.
7. Use pnpm-managed browser commands for browser verification.
8. Update this document if implementation results force a design change.
