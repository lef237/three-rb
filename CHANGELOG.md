# Changelog

## 0.1.0 - Unreleased

### Added

- Ruby scene graph, math primitives, cameras, lights, geometries, materials, textures, layers, and JSON export/load.
- Browser rendering through ruby.wasm and a delegated three.js backend.
- Browser examples and Playwright smoke tests for cube, composition, textures, cubemap, glTF/DRACO, serialization, picking, primitives, and postprocessing.
- Texture loading, cube textures, RGBE environment textures, glTF loading, DRACO decoder configuration, animation mixers, OrbitControls, instancing, raycasting, shadows, and initial EffectComposer/RenderPass/UnrealBloomPass wrappers.
- Release install smoke test for validating the built gem outside the repository load path.

### Notes

- The first release is browser-first alpha quality. Native rendering, full three.js compatibility, broad addon coverage, WebGPU, and XR are intentionally outside the initial public scope.
