# Next Work

This document is the resume point for the next implementation session. It is intentionally narrower than `docs/implementation-plan.md`: use it to decide what to do next after conversation context is lost.

Last updated: 2026-05-14.

## Current Position

The project is past the original MVP and is in Phase 8, renderer maturity. The `0.1.0` browser-first alpha target is implemented and release-gate ready; the remaining release work is manual metadata finalization and publishing after owner confirmation.

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
- Completed public API and documentation consistency pass for the current browser-first alpha scope.
- Local release gate and latest `main` CI are green for the `0.1.0` release candidate.

Do not start Phase 9 native renderer work yet. The implementation plan still recommends keeping browser rendering delegated to three.js through ruby.wasm until the browser-first API is more stable.

## Recommended Next Task

Keep the `0.1.0` release candidate current while the release is deferred. Publish only after the release owner confirms the date and RubyGems credentials.

This is the best next step because:

- The representative JSON fixture covers the current primitive/material surface, including `Sprite` / `SpriteMaterial`.
- The public docs now cover release readiness, publishing, browser example coverage, browser runtime boot contract, and the current implemented API scope.
- `lib/three/version.rb` already contains `0.1.0`.
- `CHANGELOG.md` intentionally remains `## 0.1.0 - Unreleased` until the owner confirms the release date, but its contents should continue to reflect the current release-candidate surface.
- Further feature scope should wait until after the `0.1.0` release unless an already-advertised example breaks.

## Scope

For deferred-release maintenance, keep `CHANGELOG.md`, `docs/release-readiness.md`, and this resume point aligned with the implemented release-candidate surface. Do not date the changelog, tag, push, or publish until the release owner confirms the release window.

When the owner is ready to publish, follow `docs/publishing.md`: confirm the release date, update `CHANGELOG.md`, run `bundle exec rake release:preflight`, commit the metadata update, publish the gem, tag `v0.1.0`, push `main` and the tag, then verify installation from RubyGems.

After the release is published, pick one feature target and keep the change small enough to verify through one browser example.

Candidate targets, in recommended order when there is no stronger product signal:

1. Another small primitive or material workflow only when it reuses existing object/material parameter, JSON, backend sync, and browser smoke patterns. After `Sprite` / `SpriteMaterial`, prefer this only for a concrete example gap rather than API breadth.
2. Another small postprocessing pass only when it can extend `examples/browser/postprocessing` without adding render targets. After `DotScreenPass`, prefer this only for a specific visual workflow rather than pass count.
3. Render target support, but only with a focused example that proves why it is needed.
4. A new addon loader only when a committed fixture requires it.
5. KTX2 loader after texture-compression fixture coverage and decoder-path handling are planned.

## Suggested Implementation Plan

1. While release is deferred, keep the unreleased changelog and release-readiness docs current without changing the version, date, tag, or published artifact.
2. When release is confirmed, finalize `CHANGELOG.md` with the confirmed release date.
3. Run `bundle exec rake release:preflight`.
4. Commit the release metadata with a message that does not include co-author trailers.
5. Publish and tag using `docs/publishing.md`.
6. After publishing, start the next feature from a user-visible workflow and choose exactly one feature target.
7. Add Ruby API coverage, fake adapter/backend tests, JSON export/load coverage when the object is serializable, and resource-disposal coverage when it owns GPU resources.
8. Add or extend one browser example and keep `examples/browser/README.md` in sync.
9. Add or update a deterministic Playwright smoke command in `package.json`.
10. Run Ruby tests, the affected browser smoke test, `bundle exec rake release:gem_smoke`, and `bundle exec rake release:preflight` before release work.

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

Those are valid later tasks, but they expand feature scope. The immediate gap is keeping the deferred release candidate accurate, then getting final release-owner confirmation and publishing before choosing future feature work by visible workflow and smoke-testability instead of API breadth.

## After This Task

After the next feature task, reassess in this order:

1. Keep the release gate passing after each change.
2. Decide whether the new example reveals a natural follow-up feature.
3. Delay Phase 9 native renderer work until the browser-first API is stable enough to justify a second renderer target.
