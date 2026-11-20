# Changelog

## Unreleased

### Added

- Added a dango browser example that builds a three-color dango from primitive meshes with lighting, shadows, and `OrbitControls`.
- Added a Cloudflare Pages deployment guide. In a repository checkout, `pnpm build:pages:ruby` builds a static `dist/` for the Ruby gemstone example. It bundles the Ruby entrypoint into one file, serves the browser packages under `/vendor/`, and loads ruby.wasm from jsDelivr, because the file is over the Pages 25 MiB asset limit.
- Added `examples/browser/shared/config.mjs`, which sets the URL the shared boot loads ruby.wasm from. It defaults to the local `node_modules` copy, and `globalThis.__threeRbRubyWasmUrl` overrides it. `three-rb browser` copies it into generated apps and keeps an existing copy even with `--force`.
- Browser examples and generated apps show a progress bar while ruby.wasm downloads and compiles, and suggest reloading if the page is still loading after 15 seconds.

### Changed

- Updated the pinned ruby.wasm packages, `@ruby/3.4-wasm-wasi` and `@ruby/wasm-wasi`, from a 2.9.4 nightly build to the 2.10.1 release.
- Updated the pinned three.js to 0.187.0 (r187). `MeshPhysicalMaterial#iridescence_thickness_range` is now sent to three.js as `iridescenceThicknessMinimum` and `iridescenceThicknessMaximum`, which require r187 or later.
- The Ruby gemstone and dango examples now request `PCFShadowMap`. three.js had already been rendering them with it in place of the deprecated `PCFSoftShadowMap`, which r187 removes.
- Removed the HDR environment from the Ruby gemstone example and its generated template. The bundled `studio.hdr` was a 2x2 uniform gray image that three.js r186 and earlier never applied, so the gem never showed it; from r187 on it only washed the gem out.
- `three-rb browser` now writes a `package.json` that lists only the browser runtime packages, and a `pnpm-lock.yaml` cut down to match, instead of copying the gem's own files with its test tooling and scripts. An existing `package.json` is kept, and no lockfile is written next to it.
- The shared boot aborts a ruby.wasm download that makes no progress for 20 seconds and retries it up to three times. It now chooses between `WebAssembly.compileStreaming` and `WebAssembly.compile` from the response's content type, instead of downloading the file again after a failed streaming compile.
- The browser smoke tests now generate apps with `three-rb browser`, install them with `pnpm install --frozen-lockfile`, and render them. They also fail on three.js console warnings.

### Fixed

- Textures from `TextureLoader` and the other loaders no longer make three.js warn "Texture marked for update but no image data found" on every frame until their image arrives.
- `MeshToonMaterial` no longer makes three.js warn that `flatShading` is not a property. `flat_shading` still takes effect.

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
- Browser examples and Playwright smoke tests for cube, composition, textures, cubemap, glTF/DRACO, serialization, picking, primitives, and postprocessing.
- Texture loading, cube textures, RGBE environment textures, glTF loading, DRACO decoder configuration, animation mixers, OrbitControls, instancing, picking, shadows, and loaded-asset traversal/disposal helpers.
- Initial postprocessing wrappers for `EffectComposer`, `RenderPass`, `UnrealBloomPass`, `DotScreenPass`, and `OutputPass`.
- Deterministic JSON fixture regression coverage for exporter/loader compatibility.
- Release install smoke and preflight tasks for validating the built gem outside the repository load path.

### Notes

- The first release is browser-first alpha quality. Native rendering, full three.js compatibility, broad addon coverage, WebGPU, and XR are intentionally outside the initial public scope.
