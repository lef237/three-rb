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

Do not start Phase 9 native renderer work yet. The implementation plan still recommends keeping browser rendering delegated to three.js through ruby.wasm until the browser-first API is more stable.

## Recommended Next Task

Add a browser runtime guide for embedding three.rb outside this repository's examples.

This is the best next step because:

- The browser examples now document what is covered, but users still need a concise standalone boot recipe before relying on the gem in their own pages.
- It improves public usability without expanding API scope.
- It should reduce support risk around import maps, pnpm-managed browser packages, ruby.wasm boot order, and the shared `examples/browser/shared/boot.mjs` helper.
- It gives future feature work a stable reference for what belongs in an example versus what belongs in application-specific boot code.
- It is lower risk than adding render targets, more postprocessing passes, or new loaders before the browser integration story is clearly documented.

## Scope

Add a guide under `docs/browser-runtime.md`.

The document should include:

- The expected deployment shape: Ruby code compiled/executed by ruby.wasm, with rendering delegated to pnpm-managed three.js modules.
- Required browser dependencies and the currently pinned versions from `package.json`.
- Minimum HTML/import-map requirements copied from the examples at a conceptual level, not as a second divergent boot implementation.
- How `Three::Renderers::ThreeJSRenderer` connects a Ruby scene to an existing canvas.
- How to use `examples/browser/shared/boot.mjs` as a reference implementation and when to write a custom boot file.
- What is intentionally unsupported or unstable in the browser-first alpha.
- Pointers to `examples/browser/README.md`, `docs/release-readiness.md`, and `docs/publishing.md`.

## Suggested Implementation Plan

1. Read `examples/browser/shared/boot.mjs`, one simple example boot file, and one feature-rich example boot file.
2. Create `docs/browser-runtime.md` as a user-facing guide, keeping it descriptive rather than adding another implementation surface.
3. Link it from the root `README.md` documents section and the browser example section.
4. Add a release-readiness test assertion so the guide remains packaged and discoverable.
5. Run Ruby tests. Browser smoke is optional unless browser boot code changes.

## Acceptance Criteria

- `bundle exec rake test` passes.
- Root README links to `docs/browser-runtime.md`.
- The guide points to `examples/browser/README.md` instead of duplicating the example coverage table.
- The guide documents pinned browser dependencies, import-map expectations, renderer/canvas setup, and current alpha limitations.
- `bundle exec rake release:gem_smoke` still passes.

Optional after the browser runtime guide task:

- Run `bundle exec rake release:preflight` if browser boot code changed.
- Run `pnpm benchmark:browser` only if synchronization or renderer internals changed.

## What Not To Do Next

Do not prioritize these before the browser runtime guide unless there is a clear product need:

- KTX2 loader.
- Additional postprocessing passes.
- Render target API.
- WebGPU renderer.
- Native renderer.
- Broad public API documentation beyond the current README, release readiness, implementation plan, browser examples overview, and browser runtime guide.

Those are valid later tasks, but they expand feature scope. The immediate gap is making the browser runtime setup understandable outside the repository examples.

## After This Task

After the browser runtime guide is in place, reassess in this order:

1. Add new material classes, postprocessing passes, render targets, or loaders only with a dedicated example and smoke test.
2. Keep the release gate passing after each change.
3. Delay Phase 9 native renderer work until the browser-first API is stable enough to justify a second renderer target.
