# Changelog

## 0.1.0 - Unreleased

### Added

- Ruby scene graph, math primitives, cameras, lights, geometries, textures, layers, raycasting helpers, and JSON export/load.
- Mesh, instanced mesh, line, points, and sprite object support.
- Common material APIs including basic, Lambert, Phong, standard, physical, matcap, toon, normal, shadow, line, points, and sprite materials.
- Browser rendering through ruby.wasm and a delegated three.js backend.
- Browser examples and Playwright smoke tests for cube, composition, textures, cubemap, glTF/DRACO, serialization, picking, primitives, and postprocessing.
- Texture loading, cube textures, RGBE environment textures, glTF loading, DRACO decoder configuration, animation mixers, OrbitControls, instancing, picking, shadows, and loaded-asset traversal/disposal helpers.
- Initial postprocessing wrappers for `EffectComposer`, `RenderPass`, `UnrealBloomPass`, `DotScreenPass`, and `OutputPass`.
- Deterministic JSON fixture regression coverage for exporter/loader compatibility.
- Release install smoke and preflight tasks for validating the built gem outside the repository load path.

### Notes

- The first release is browser-first alpha quality. Native rendering, full three.js compatibility, broad addon coverage, WebGPU, and XR are intentionally outside the initial public scope.
