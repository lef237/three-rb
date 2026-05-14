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

Do not start Phase 9 native renderer work yet. The implementation plan still recommends keeping browser rendering delegated to three.js through ruby.wasm until the browser-first API is more stable.

## Recommended Next Task

Add `examples/browser/README.md` to summarize what each browser example verifies.

This is the best next step because:

- It turns the existing browser smoke coverage into a readable feature map.
- It helps future contributors choose the right example to extend instead of adding overlapping examples.
- It supports the implementation-plan rule that new browser-facing features should have a dedicated example and deterministic smoke coverage.
- It improves user-facing value without expanding API scope.
- It gives the next implementation session a low-risk documentation task before deciding whether to add render targets, more postprocessing passes, or new loaders.

## Scope

Add an overview document under `examples/browser/README.md`.

The document should include:

- How to run all examples from the repository root.
- How to run all browser smoke tests.
- A table or concise list for each existing example:
  - path,
  - primary APIs covered,
  - smoke test command,
  - why the example exists.
- A note that new browser-facing features should add or extend an example and include smoke coverage.

## Suggested Implementation Plan

1. Read `package.json` browser scripts and existing `examples/browser/*/README.md` files.
2. Create `examples/browser/README.md`.
3. Link it from the root `README.md` documents or browser example section.
4. Add a small repository test that confirms every `test:browser:*` script has a matching example entry, if practical.
5. Run Ruby tests. Browser smoke is optional unless example code changes.

## Acceptance Criteria

- `bundle exec rake test` passes.
- Root README links to `examples/browser/README.md`.
- The overview lists every current browser example: cube, composition, textures, cubemap, glTF, serialization, picking, primitives, and postprocessing.
- The overview documents the matching smoke command for each example.
- `bundle exec rake release:gem_smoke` still passes.

Optional after the examples overview task:

- Run `bundle exec rake release:preflight` if browser example code changed.
- Run `pnpm benchmark:browser` only if synchronization or renderer internals changed.

## What Not To Do Next

Do not prioritize these before the examples overview task unless there is a clear product need:

- KTX2 loader.
- Additional postprocessing passes.
- Render target API.
- WebGPU renderer.
- Native renderer.
- Broad public API documentation beyond the current README, release readiness, implementation plan, and browser examples overview.

Those are valid later tasks, but they expand feature scope. The immediate gap is making the already-tested browser coverage easier to discover and maintain.

## After This Task

After the browser examples overview is in place, reassess in this order:

1. Add a browser runtime guide only if users need to embed three.rb outside this repository's examples.
2. Add new material classes, postprocessing passes, render targets, or loaders only with a dedicated example and smoke test.
3. Keep the release gate passing after each change.
