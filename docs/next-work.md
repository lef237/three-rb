# Next Work

This document is the resume point for the next implementation session. It is intentionally narrower than `docs/implementation-plan.md`: use it to decide what to do next after conversation context is lost.

Last updated: 2026-05-13.

## Current Position

The project is past the original MVP and is in Phase 8, renderer maturity.

Recent completed work:

- `MeshPhysicalMaterial` support.
- `RGBELoader` / `RGBETexture` support.
- `DRACOLoader` integration through `GLTFLoader#draco_decoder_path`.
- Initial postprocessing support with `EffectComposer`, `RenderPass`, and `UnrealBloomPass`.
- Release readiness checks, gem install smoke, release preflight, and publishing documentation.

Do not start Phase 9 native renderer work yet. The implementation plan still recommends keeping browser rendering delegated to three.js through ruby.wasm until the browser-first API is more stable.

## Recommended Next Task

Add saved fixture regression coverage for `Three::Exporters::ThreeJSONExporter` and `Three::Loaders::ThreeJSONLoader`.

This is the best next step because:

- It matches `docs/implementation-plan.md` Next Tasks item 4.
- JSON export/load is already implemented and visible to users.
- The exported format will become harder to change after public use.
- Fixtures catch accidental format drift when future material, texture, geometry, or scene features are added.
- It improves release quality without expanding feature scope.

## Scope

Add a small fixture set under `test/fixtures/`.

Recommended first fixture:

- A scene with:
  - `Scene`
  - `PerspectiveCamera`
  - `AmbientLight`
  - `DirectionalLight`
  - `Group`
  - `Mesh` with `BoxGeometry`
  - `MeshPhysicalMaterial`
  - `Texture` assigned to at least `map`, `roughness_map`, and one physical-material texture slot
  - `InstancedMesh` with a few matrices and colors
  - `Line` and `Points` using `BufferGeometry`
  - scene `background` or `environment` texture if practical

Keep the fixture Ruby-authored. Do not include external loaded glTF handles in the first fixture because `ExternalObject3D` is intentionally opaque and has a separate design document.

## Suggested Implementation Plan

1. Create a fixture builder helper, for example `test/support/scene_fixture_builder.rb`.
2. Generate a deterministic export with `Three::Exporters::ThreeJSONExporter.new(deterministic_ids: true)`.
3. Store the JSON fixture under `test/fixtures/scene_export_v1.json`.
4. Add tests that:
   - assert the current export matches the saved fixture,
   - parse the saved fixture with `Three::Loaders::ThreeJSONLoader`,
   - verify the loaded object graph shape,
   - verify shared resources are preserved where applicable,
   - verify material texture slots round-trip.
5. If the fixture changes intentionally, update the fixture in the same commit and explain why in the commit message or test name.

Prefer pretty JSON with stable key order. The exporter already supports deterministic IDs; if key order is not stable enough, add a test-side canonical JSON helper instead of changing public exporter output unless there is a product reason.

## Acceptance Criteria

- `bundle exec rake test` passes.
- Fixture tests fail on accidental changes to exported JSON structure.
- Fixture tests exercise both export and load paths.
- No browser example is required for this task unless the implementation reveals a browser-only issue.
- `bundle exec rake release:gem_smoke` still passes.

Optional after the fixture task:

- Run `bundle exec rake release:preflight` if browser-facing code changed.
- Run `pnpm benchmark:browser` only if synchronization or renderer internals changed.

## What Not To Do Next

Do not prioritize these before the fixture regression task unless there is a clear product need:

- KTX2 loader.
- Additional postprocessing passes.
- Render target API.
- WebGPU renderer.
- Native renderer.
- Broad public API documentation beyond the current README, release readiness, and implementation plan.

Those are valid later tasks, but they expand feature scope. The immediate gap is format stability and regression coverage for already-implemented behavior.

## After This Task

After saved fixture regression coverage is in place, reassess in this order:

1. Add `examples/browser/README.md` to summarize what each browser example verifies.
2. Add a browser runtime guide only if users need to embed three.rb outside this repository's examples.
3. Add new material classes, postprocessing passes, render targets, or loaders only with a dedicated example and smoke test.
4. Keep the release gate passing after each change.
