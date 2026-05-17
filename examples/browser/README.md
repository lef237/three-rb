# Browser Examples

These examples are the browser-facing coverage map for three-rb's browser-first alpha. They run Ruby through ruby.wasm, load pnpm-managed three.js packages, and render through `Three::Renderers::ThreeJSRenderer`.

Examples that need fixtures keep those files under their own `assets/` directory so each sample remains self-contained.

## Run Examples

Install browser dependencies and serve the repository root:

```sh
pnpm install
ruby -run -e httpd . -p 8000
```

If Ruby reports that `webrick` is not found, install it once with `gem install webrick`. Ruby 3.0 and later no longer include WEBrick as a standard library.

Open an example URL:

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

## Smoke Tests

Run all browser smoke tests:

```sh
pnpm install
pnpm exec playwright install chromium
pnpm test:browser
```

Run one smoke test by using the command listed in the table below.

| Example | Primary APIs covered | Smoke command | Why it exists |
| --- | --- | --- | --- |
| `examples/browser/ruby/` | `BufferGeometry`, `Float32BufferAttribute`, `MeshPhysicalMaterial`, `RGBELoader`, `FontLoader`, `TextGeometry`, `OrbitControls`, shadows | `pnpm test:browser:ruby` | Provides the first visual sample: a Ruby-authored faceted red gemstone with a three-dimensional `three-rb` title. |
| `examples/browser/cube/` | `Scene`, `PerspectiveCamera`, `BoxGeometry`, `Mesh`, `MeshBasicMaterial`, `ThreeJSRenderer`, animation loop | `pnpm test:browser:cube` | Verifies the smallest Ruby-authored scene can boot through ruby.wasm and draw nonblank WebGL pixels through the three.js renderer path. |
| `examples/browser/composition/` | `OrthographicCamera`, ambient/directional/point/hemisphere lights, shadows, `ShadowMaterial`, `Group`, `InstancedMesh`, `TextureLoader`, `OrbitControls`, material/texture disposal | `pnpm test:browser:composition` | Exercises the broad scene-composition path used by richer browser scenes, including dynamic material updates and camera controls. |
| `examples/browser/textures/` | `TextureLoader`, `RGBELoader`, repeat/wrap/filter/UV-transform settings, `MeshPhysicalMaterial`, `MeshMatcapMaterial`, `MeshToonMaterial`, physical, matcap, and toon texture slots, scene environment | `pnpm test:browser:textures` | Verifies browser texture loading, HDR environment synchronization, and the current material texture bridge. |
| `examples/browser/cubemap/` | `CubeTextureLoader`, `CubeTexture`, scene `background`, scene `environment`, reflective `MeshStandardMaterial` | `pnpm test:browser:cubemap` | Keeps cubemap background/environment behavior covered separately from ordinary 2D texture loading. |
| `examples/browser/gltf/` | `GLTFLoader`, `DRACOLoader` decoder path, loaded external scenes, `AnimationMixer`, `Clock`, loaded subtree disposal | `pnpm test:browser:gltf` | Verifies that external assets can be loaded, animated, attached to Ruby scenes, and disposed through the renderer API. |
| `examples/browser/serialization/` | `ThreeJSONExporter`, `ThreeJSONLoader`, deterministic ids, shared geometry/material/texture resources, loaded scene rendering | `pnpm test:browser:serialization` | Confirms exported Ruby scenes round-trip through JSON and render after loading. |
| `examples/browser/picking/` | `Raycaster`, pointer-to-camera coordinates, intersection mapping back to Ruby `Object3D`, selected material updates | `pnpm test:browser:picking` | Verifies browser event coordinates can drive Ruby-side picking and mutate rendered objects. |
| `examples/browser/primitives/` | `BufferGeometry`, `Float32BufferAttribute`, `Line`, `Points`, `Sprite`, `LineBasicMaterial`, `PointsMaterial`, `SpriteMaterial` | `pnpm test:browser:primitives` | Covers non-`Mesh` primitive rendering, generic buffer attribute synchronization, and textured billboard markers. |
| `examples/browser/postprocessing/` | `EffectComposer`, `RenderPass`, `UnrealBloomPass`, `DotScreenPass`, `OutputPass`, composer sizing, pass property/uniform updates, `composer.render` | `pnpm test:browser:postprocessing` | Verifies the explicit postprocessing render path stays separate from direct renderer rendering and remains smoke-tested. |

## Adding Browser Coverage

New browser-facing features should add or extend one of these examples and include deterministic smoke coverage. Prefer extending an existing example when the feature strengthens the same workflow; add a new example when it introduces a distinct API surface such as a new loader family, render target workflow, or postprocessing pipeline.

Keep new Ruby entrypoints Ruby-only: use `Three::Browser.run`, `app.resize_renderer`, `app.on_resize`, `app.animation_loop`, `app.element`, `app.on_key`, `app.on_pointer`, `app.pointer_ndc`, `app.storage`, and `app.expose` instead of `require "js"` or direct `JS.global` calls. If a feature needs browser or three.js APIs that are not wrapped yet, add a small Ruby helper or backend method first. Use `Three::Browser.js` only as an explicit escape hatch and keep it isolated from scene construction code.
