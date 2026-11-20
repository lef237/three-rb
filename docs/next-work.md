# Next Work

This document is the resume point for the next implementation session. It is intentionally narrower than `docs/implementation-plan.md`: use it to decide what to do next after conversation context is lost.

Last updated: 2026-11-20.

## Current Position

The project is past the original MVP and is in Phase 8, renderer maturity. `0.1.0`, `0.2.0`, and `0.2.1` are published on RubyGems. Changes since `0.2.1` are collected under the `Unreleased` heading in `CHANGELOG.md` for the next release.

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
- Browser examples were moved to Ruby-only entrypoints that use `Three::Browser` helpers instead of application-level `require "js"` or `JS.global`.
- Added the `three-rb browser` executable and generator for standalone Ruby-only browser examples.
- Release install smoke now validates the installed executable and generated browser app shape outside the repository load path.
- Local release gate and `main` CI were green for each published release.

Since `0.2.1`:

- Dango browser example with primitive meshes, lighting, shadows, and smoke coverage.
- Cloudflare Pages deployment guide and the repository's `pnpm build:pages:ruby` build, which bundles the Ruby entrypoint and loads ruby.wasm from jsDelivr.
- Shared `config.mjs` for the ruby.wasm URL, a loading progress bar, and stalled-download retries in the shared boot.
- ruby.wasm 2.10.1 and three.js 0.187.0 (r187), including the r187 iridescence and shadow-map changes.
- Generated apps get a runtime-only `package.json` and matching lockfile, and a smoke test generates, installs, and renders them.
- Browser smoke tests fail on three.js console warnings.

Do not start Phase 9 native renderer work yet. The implementation plan still recommends keeping browser rendering delegated to three.js through ruby.wasm until the browser-first API is more stable.

## Recommended Next Task

Publish the changes under `Unreleased` as the next release once the release owner confirms the version and RubyGems credentials.

This is the best next step because:

- `0.2.1` predates the r187 update, the ruby.wasm 2.10.1 release, and the generated-app fixes, so installed users still get the older runtime.
- The `Unreleased` section in `CHANGELOG.md` already describes everything since `0.2.1`.
- Further feature scope should wait until after that release unless an already-advertised example breaks.

## Scope

Until the release, keep `CHANGELOG.md`, `docs/release-readiness.md`, and this resume point aligned with what is on `main`. Do not tag, push, or publish until the release owner confirms.

When the owner is ready to publish, follow `docs/publishing.md`: bump `lib/three/version.rb`, replace the current changelog heading `## Unreleased` with the version and date, run `bundle exec rake release:preflight`, commit the metadata update, publish the gem, tag the release, push `main` and the tag, then verify installation from RubyGems.

After the release is published, pick one feature target and keep the change small enough to verify through one browser example.

Candidate targets, in recommended order when there is no stronger product signal:

1. Another small primitive or material workflow only when it reuses existing object/material parameter, JSON, backend sync, and browser smoke patterns. After `Sprite` / `SpriteMaterial`, prefer this only for a concrete example gap rather than API breadth.
2. Another small postprocessing pass only when it can extend `examples/browser/postprocessing` without adding render targets. After `DotScreenPass`, prefer this only for a specific visual workflow rather than pass count.
3. Render target support, but only with a focused example that proves why it is needed.
4. A new addon loader only when a committed fixture requires it.
5. KTX2 loader after texture-compression fixture coverage and decoder-path handling are planned.

## Suggested Implementation Plan

1. Until the release is confirmed, keep the current changelog heading, release-readiness docs, and publishing checklist aligned with `main` without changing the version, tag, or published artifact.
2. When the release is confirmed, bump the version and date the `Unreleased` heading in `CHANGELOG.md`.
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

Those are valid later tasks, but they expand feature scope. The immediate gap is publishing the unreleased changes, then choosing future feature work by visible workflow and smoke-testability instead of API breadth.

## After This Task

After the next feature task, reassess in this order:

1. Keep the release gate passing after each change.
2. Decide whether the new example reveals a natural follow-up feature.
3. Delay Phase 9 native renderer work until the browser-first API is stable enough to justify a second renderer target.
