# Release Readiness

This document defines the quality gate for publishing the first public `three.rb` release.

## Current Position

The project is past the original MVP. It is now in Phase 8, renderer maturity: core Ruby scene authoring, browser rendering, JSON export/load, interaction, asset loading, instancing, picking, shadows, and initial postprocessing are implemented and covered by unit or browser smoke tests.

The first public release should be positioned as browser-first alpha. The stable promise is narrow: users can build Ruby-authored scenes and render them in a browser through ruby.wasm and the delegated three.js backend. Native rendering and full three.js API compatibility are not part of the first release.

## Public Scope

Included in the first public scope:

- Ruby object model for scenes, groups, transforms, cameras, lights, geometries, materials, textures, and common math primitives.
- Browser rendering through `Three::Renderers::ThreeJSRenderer`, ruby.wasm, and `three@0.184.0`.
- Dirty-tracked synchronization from Ruby objects into three.js handles.
- JSON export/load for Ruby-authored scenes.
- JavaScript-delegated browser integrations for textures, cube maps, RGBE environment maps, glTF, DRACO, animation mixers, OrbitControls, raycasting, instancing, shadows, and initial postprocessing with composer/render/bloom/output passes.
- Browser examples and smoke tests that verify visible rendering paths.

Explicitly out of scope for the first public scope:

- A native Ruby renderer.
- Full three.js API coverage.
- Compatibility aliases for every camelCase three.js API.
- Broad addon coverage beyond examples that are already tested.
- WebGPU, WebXR, node materials, editor integration, physics, and production asset pipeline guarantees.

## Required Gate

Run these before publishing or tagging:

```sh
pnpm install --frozen-lockfile --ignore-scripts
pnpm audit --audit-level moderate
pnpm audit signatures
pnpm exec playwright install chromium
bundle exec rake release:preflight
```

Optional but recommended when renderer internals change:

```sh
pnpm benchmark:browser
```

## Release Criteria

The release is acceptable when:

- The required gate passes locally and in CI.
- `CHANGELOG.md` describes the release as unreleased or tagged with the final date.
- README documents the browser-first alpha scope and unsupported areas.
- `bundle exec rake release:gem_smoke` proves the built gem can be installed into a temporary `GEM_HOME` and used without the repository `lib/` path.
- `bundle exec rake release:preflight` proves the Ruby tests, install smoke, browser smoke tests, and gem build pass without publishing.
- Browser smoke tests cover every advertised browser example.

## Recommended Next Work

Before expanding feature scope, prefer:

1. Keep release checks fast and deterministic.
2. Keep fixture-based JSON export/load regression tests current.
3. Improve public docs around browser examples, browser boot, and unsupported APIs; see `docs/next-work.md`.
4. Add new material classes, postprocessing passes, render targets, or loaders only when a dedicated example and smoke test need them.
5. Treat KTX2, WebGPU, WebXR, and native rendering as post-0.1 planning items.
