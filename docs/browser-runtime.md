# Browser Runtime

This guide describes the current browser runtime shape for embedding three-rb outside the repository examples. The browser runtime is still browser-first alpha: Ruby builds the scene graph, ruby.wasm runs the Ruby code, and pnpm-managed three.js modules do the actual WebGL rendering.

For the example coverage map and per-example smoke commands, see `examples/browser/README.md`.

## Runtime Shape

A browser page using three-rb needs four pieces:

1. An HTTP-served page with a canvas element.
2. An import map or bundler setup that resolves ruby.wasm, three.js, and three.js addon modules.
3. A JavaScript boot module that exposes the required three.js constructors to Ruby and starts ruby.wasm.
4. A Ruby entrypoint that requires `three`, creates a scene inside `Three::Browser.run`, and renders through `Three::Renderers::ThreeJSRenderer`.

Do not use `file://` for browser runs. The examples assume an HTTP server because browser module loading, wasm loading, and asset loading all need stable URL resolution.

## Browser Dependencies

The runtime currently follows the pinned versions in `package.json`:

- `@bjorn3/browser_wasi_shim@0.4.2`
- `@ruby/3.4-wasm-wasi@2.9.4-2026-05-11-a`
- `@ruby/wasm-wasi@2.9.4-2026-05-11-a`
- `three@0.184.0`

Install them from the repository root with:

```sh
pnpm install
```

Keep these pins synchronized with browser smoke coverage. The public Ruby API and the JavaScript delegated backend are coupled closely enough that dependency drift should go through `pnpm test:browser` before release work.

## HTML Requirements

The page needs a canvas that Ruby can select:

```html
<canvas id="scene"></canvas>
```

When using import maps like the examples, the page also needs mappings for ruby.wasm, three.js, and three.js addons:

```html
<script type="importmap">
  {
    "imports": {
      "@bjorn3/browser_wasi_shim": "/node_modules/@bjorn3/browser_wasi_shim/dist/index.js",
      "@ruby/wasm-wasi/browser": "/node_modules/@ruby/wasm-wasi/dist/esm/browser.js",
      "three": "/node_modules/three/build/three.module.js",
      "three/addons/": "/node_modules/three/examples/jsm/"
    }
  }
</script>
```

Applications can use a bundler instead of an import map, but the same modules and addon paths must be available to the JavaScript boot module.

## JavaScript Boot Contract

Use `examples/browser/shared/boot.mjs` as the reference implementation. Example-local boot files are intentionally small; they pass the Ruby entrypoint and clear color into the shared boot helper.

The boot module is responsible for:

- Importing `DefaultRubyVM` from `@ruby/wasm-wasi/browser`.
- Importing `three` and any addon constructors used by Ruby.
- Assigning `globalThis.THREE` before Ruby creates `Three::Renderers::ThreeJSRenderer`.
- Assigning addon constructors before Ruby calls addon wrappers:
  - `globalThis.THREE_GLTF_LOADER`
  - `globalThis.THREE_DRACO_LOADER`
  - `globalThis.THREE_RGBE_LOADER`
  - `globalThis.THREE_ORBIT_CONTROLS`
  - `globalThis.THREE_EFFECT_COMPOSER`
  - `globalThis.THREE_RENDER_PASS`
  - `globalThis.THREE_UNREAL_BLOOM_PASS`
  - `globalThis.THREE_DOT_SCREEN_PASS`
  - `globalThis.THREE_OUTPUT_PASS`
- Setting `globalThis.__threeReady` to a promise Ruby can wait on.
- Loading `/node_modules/@ruby/3.4-wasm-wasi/dist/ruby+stdlib.wasm`.
- Starting the Ruby VM and loading the Ruby entrypoint through `JS::RequireRemote`.

The shared helper also installs optional render helpers used by smoke tests to draw immediately from Ruby renderer calls and expose render counters for deterministic assertions. Custom applications can keep that behavior or call directly into three.js through the renderer backend fallback.

Write a custom boot module when the application has different asset paths, a bundler output path, a smaller addon set, a custom status/error UI, or a deployment layout that does not match the repository root. Keep the same global constructor contract unless the Ruby backend gains a different injection API.

## Ruby Entrypoint

The Ruby side should require the library, create a scene inside `Three::Browser.run`, and attach the renderer to the existing canvas. `Three::Browser.run` waits for the JavaScript boot module and handles the example status/error UI, so application scene code does not need to call `JS.global` directly:

```ruby
require_relative "../../../lib/three"

Three::Browser.run(starting: "Starting Ruby scene") do |app|
  scene = Three::Scene.new
  camera = Three::PerspectiveCamera.new(70, aspect: 1.0, near: 0.1, far: 100)
  camera.position.z = 3

  mesh = Three::Mesh.new(
    Three::BoxGeometry.new(1, 1, 1),
    Three::MeshBasicMaterial.new(color: 0x4ed08f)
  )
  scene.add(mesh)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false
  )

  app.resize_renderer(renderer, camera)
  renderer.render(scene, camera)
end
```

`canvas:` may be a CSS selector string or a JavaScript canvas object. Selector strings are resolved with `document.querySelector`.

For responsive layouts, use `app.resize_renderer(renderer, camera)` for perspective cameras. For custom orthographic sizing, pass a block and update the camera before the helper sets the renderer size.

For animation, call `renderer.animation_loop`:

```ruby
renderer.animation_loop do
  mesh.rotation.x += 0.01
  mesh.rotation.y += 0.015
  renderer.render(scene, camera)
end
```

For postprocessing, render through `composer.render(scene, camera)` instead of `renderer.render(scene, camera)` after configuring `Three::Postprocessing::EffectComposer` and its passes.

## Current Limits

The browser runtime intentionally does not promise full three.js compatibility yet.

- There is no Ruby-native OpenGL, Vulkan, WebGPU, or software renderer.
- Rendering is delegated to three.js through ruby.wasm.
- Addon wrappers only work when their JavaScript constructors are registered on `globalThis`.
- The JavaScript boot module is still required to import ES modules and start ruby.wasm, even though ordinary Ruby scene entrypoints can stay Ruby-only.
- The first public scope does not include stable APIs for every loader, material, render target, postprocessing pass, WebGPU, or XR workflow.
- `examples/browser/shared/boot.mjs` is a reference implementation for this repository's examples, not a separate stable package.
- `preserveDrawingBuffer: true` is useful for deterministic canvas smoke tests, but applications do not need it by default.

## Verification

Use the browser examples as executable documentation:

```sh
pnpm test:browser
```

Before release work, run the release gates documented in `docs/release-readiness.md` and the publishing checklist in `docs/publishing.md`. Browser boot changes should go through `bundle exec rake release:preflight` because that includes the Ruby tests, gem install smoke, and browser smoke tests.
