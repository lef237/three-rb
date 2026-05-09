# Changelog

## 0.2.1 - 2026-05-17

### Added

- Added a generated Ruby browser example template that copies the full gemstone example, including its local HDR asset.
- Added generator coverage for Ruby example asset copying and Ruby-only browser entrypoints.

### Changed

- Moved browser example assets into example-local asset directories so generated examples and smoke tests use self-contained paths.
- Strengthened release readiness checks for the browser generator template and installed executable.

## 0.2.0 - 2026-05-17

### Added

- Expanded `Three::Browser` helpers so browser examples can stay in Ruby without direct application-level `require "js"` or `JS.global` usage.
- Added the `three-rb browser` generator for creating standalone browser apps with Ruby-only entrypoints.
- Added a Ruby gemstone browser example with deterministic smoke coverage.
- Added scene fog and override material support.
- Added manual `Object3D` matrix support.
- Added text geometry and font loader APIs.
- Added JSON resource metadata preservation for exported and loaded scenes.

### Changed

- Converted browser examples to the Ruby browser helper API and shared browser boot path.
- Improved browser addon error messages with more actionable guidance.
- Strengthened release checks for installed gem behavior, the installed executable, and generated browser apps.
- Expanded browser runtime and standalone app documentation.

## 0.1.0 - 2026-05-15

### Added

- Ruby scene graph, math primitives, cameras, lights, geometries, textures, layers, raycasting helpers, and JSON export/load.
- Mesh, instanced mesh, line, points, and sprite object support.
- Common material APIs including basic, Lambert, Phong, standard, physical, matcap, toon, normal, shadow, line, points, and sprite materials.
- Browser rendering through ruby.wasm and a delegated three.js backend.
- `Three::Browser` helpers and a `three-rb browser` generator for Ruby-only browser entrypoints that avoid application-level `require "js"` and `JS.global` calls.
- Browser examples and Playwright smoke tests for cube, composition, textures, cubemap, glTF/DRACO, serialization, picking, primitives, and postprocessing.
- Texture loading, cube textures, RGBE environment textures, glTF loading, DRACO decoder configuration, animation mixers, OrbitControls, instancing, picking, shadows, and loaded-asset traversal/disposal helpers.
- Initial postprocessing wrappers for `EffectComposer`, `RenderPass`, `UnrealBloomPass`, `DotScreenPass`, and `OutputPass`.
- Deterministic JSON fixture regression coverage for exporter/loader compatibility.
- Release install smoke and preflight tasks for validating the built gem, installed executable, and generated browser app outside the repository load path.

### Notes

- The first release is browser-first alpha quality. Native rendering, full three.js compatibility, broad addon coverage, WebGPU, and XR are intentionally outside the initial public scope.
