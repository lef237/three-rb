# Next Work

This document is the resume point for the next implementation session. It is intentionally narrower than `docs/implementation-plan.md`: use it to decide what to do next after conversation context is lost.

Last updated: 2026-05-14.

## Current Position

The project is past the original MVP and is in Phase 8, renderer maturity.

Recent completed work:

- `MeshPhysicalMaterial` support.
- `RGBELoader` / `RGBETexture` support.
- `DRACOLoader` integration through `GLTFLoader#draco_decoder_path`.
- Initial postprocessing support with `EffectComposer`, `RenderPass`, and `UnrealBloomPass`.
- Release readiness checks, gem install smoke, release preflight, and publishing documentation.
- Saved JSON export/load fixture regression coverage for `Three::Exporters::ThreeJSONExporter` and `Three::Loaders::ThreeJSONLoader`.
- Browser examples overview and smoke command map for cube, composition, textures, cubemap, glTF, serialization, picking, primitives, and postprocessing.
- Browser runtime guide documenting the current ruby.wasm, import-map, `globalThis.THREE`, and `Three::Renderers::ThreeJSRenderer` boot contract.
- `Three::Postprocessing::OutputPass` support in the postprocessing composer example and browser smoke test.
- `MeshMatcapMaterial` support with matcap texture-slot sync, JSON export/load, resource disposal, and texture browser smoke coverage.
- `ShadowMaterial` support with backend sync, JSON export/load, and composition browser smoke coverage.
- `MeshToonMaterial` support with gradient-map texture-slot sync, JSON export/load, resource disposal, and texture browser smoke coverage.
- `Three::Postprocessing::DotScreenPass` support with composer integration, uniform update coverage, browser runtime boot contract updates, and postprocessing browser smoke coverage.
- `Sprite` / `SpriteMaterial` support with textured billboard marker sync, JSON export/load, resource disposal, and primitives browser smoke coverage.
- Saved JSON fixture coverage now includes `Sprite` / `SpriteMaterial` so the representative exporter/loader regression fixture matches the current primitive surface.

Do not start Phase 9 native renderer work yet. The implementation plan still recommends keeping browser rendering delegated to three.js through ruby.wasm until the browser-first API is more stable.

## Recommended Next Task

Do a public API and documentation consistency pass before selecting the next browser-facing feature.

This is the best next step because:

- The representative JSON fixture now covers the current primitive/material surface, including `Sprite` / `SpriteMaterial`.
- The public docs cover release readiness, publishing, browser example coverage, and the browser runtime boot contract, but they should be checked against the latest implemented API before more feature scope is added.
- Further progress should come from a concrete browser workflow, not from broad API mirroring.
- The current implementation plan says KTX2 and other decoder loaders should wait until fixture coverage needs them.
- Additional postprocessing passes should wait unless they can strengthen `examples/browser/postprocessing` without forcing an oversized render-target API.
- Render targets are useful, but they expand renderer surface area and should be added only when an example requires them.

## Scope

First compare `README.md`, `docs/browser-runtime.md`, `docs/release-readiness.md`, `examples/browser/README.md`, and `docs/implementation-plan.md` against the current API surface. Keep any edits factual and narrow: document existing supported behavior, remove stale next-step wording, and avoid broad reference documentation.

After that pass, pick one feature target and keep the change small enough to verify through one browser example.

Candidate targets, in recommended order when there is no stronger product signal:

1. Another small primitive or material workflow only when it reuses existing object/material parameter, JSON, backend sync, and browser smoke patterns. After `Sprite` / `SpriteMaterial`, prefer this only for a concrete example gap rather than API breadth.
2. Another small postprocessing pass only when it can extend `examples/browser/postprocessing` without adding render targets. After `DotScreenPass`, prefer this only for a specific visual workflow rather than pass count.
3. Render target support, but only with a focused example that proves why it is needed.
4. A new addon loader only when a committed fixture requires it.
5. KTX2 loader after texture-compression fixture coverage and decoder-path handling are planned.

## Suggested Implementation Plan

1. Run the public API/docs consistency pass and keep the changes scoped to already implemented behavior.
2. Start the next feature from a user-visible workflow and choose exactly one feature target.
3. Add Ruby API coverage, fake adapter/backend tests, JSON export/load coverage when the object is serializable, and resource-disposal coverage when it owns GPU resources.
4. Add or extend one browser example and keep `examples/browser/README.md` in sync.
5. Add or update a deterministic Playwright smoke command in `package.json`.
6. Run Ruby tests, the affected browser smoke test, `bundle exec rake release:gem_smoke`, and `bundle exec rake release:preflight` before release work.

## Acceptance Criteria

- `bundle exec rake test` passes.
- The chosen feature has one dedicated or clearly extended browser example.
- `examples/browser/README.md` documents the new coverage.
- `package.json` has a matching `test:browser:*` command when a new example is added.
- The affected browser smoke test passes.
- `bundle exec rake release:gem_smoke` still passes.

Optional after the next feature task:

- Run `bundle exec rake release:preflight` before release work or when browser/runtime code changed.
- Run `pnpm benchmark:browser` only if synchronization or renderer internals changed.

## What Not To Do Next

Do not prioritize these without a clear product need:

- KTX2 loader.
- Additional postprocessing passes.
- Render target API.
- WebGPU renderer.
- Native renderer.
- Broad public API documentation beyond the current README, release readiness, implementation plan, browser examples overview, and browser runtime guide.

Those are valid later tasks, but they expand feature scope. The immediate gap is choosing feature work by visible workflow and smoke-testability instead of API breadth.

## After This Task

After the next feature task, reassess in this order:

1. Keep the release gate passing after each change.
2. Decide whether the new example reveals a natural follow-up feature.
3. Delay Phase 9 native renderer work until the browser-first API is stable enough to justify a second renderer target.
