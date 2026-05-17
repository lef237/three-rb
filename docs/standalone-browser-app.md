# Standalone Browser App

This guide shows how to make a small browser app outside the three-rb repository with your own Ruby entrypoint.

The current browser runtime is still alpha. A standalone app needs a small JavaScript boot file because the browser must start ruby.wasm, expose three.js constructors, and then load your Ruby file over HTTP.

## Generate The App

Install the gem, create a project directory, and generate a Ruby-only browser example:

```sh
mkdir hello-three-rb
cd hello-three-rb

gem install three-rb
three-rb browser examples/browser/quickstart
```

If you installed through Bundler, run:

```sh
bundle exec three-rb browser examples/browser/quickstart
```

Use `three-rb browser examples/browser/ruby` instead when you want the richer Ruby gemstone sample. It generates the same browser runtime shape and keeps its HDR file under `examples/browser/ruby/assets/`.

The generator creates:

- `package.json` and `pnpm-lock.yaml`
- `lib/`, copied from the installed gem
- `examples/browser/shared/boot.mjs`
- `examples/browser/quickstart/index.html`
- `examples/browser/quickstart/boot.mjs`
- `examples/browser/quickstart/main.rb`
- `examples/browser/quickstart/README.md`

For templates that need assets, the generator also creates an `assets/` directory inside the example.

Copying `lib/` puts the installed gem's Ruby source in the served app directory. The browser Ruby VM loads Ruby files over HTTP, so this is the current standalone workflow.

Pass `--force` only when you want to overwrite generated example files:

```sh
three-rb browser examples/browser/quickstart --force
```

## Ruby Entrypoint

The generated `examples/browser/quickstart/main.rb` is plain Ruby scene code. It does not require `js` or call `JS.global`:

```ruby
# frozen_string_literal: true

require_relative "../../../lib/three"

Three::Browser.run(starting: "Starting Ruby scene") do |app|
  scene = Three::Scene.new
  camera = Three::PerspectiveCamera.new(70, aspect: 1.0, near: 0.1, far: 100)
  camera.position.z = 3

  cube = Three::Mesh.new(
    Three::BoxGeometry.new(1, 1, 1),
    Three::MeshBasicMaterial.new(color: 0x4ed08f)
  )
  scene.add(cube)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false
  )
  renderer.set_clear_color(0x101418, 1)

  app.resize_renderer(renderer, camera)
  renderer.render(scene, camera)

  app.animation_loop(renderer) do
    cube.rotation.x += 0.01
    cube.rotation.y += 0.015
    renderer.render(scene, camera)
  end
end
```

Keep ordinary scene code inside `Three::Browser.run`. Use `app.resize_renderer(renderer, camera)` for responsive canvas sizing, `app.animation_loop(renderer)` for animation, and `app.on_key`, `app.on_pointer`, `app.pointer_ndc`, or `app.storage` before reaching for direct JavaScript access.

## Run It

Install browser packages, serve the app directory, and open the page:

```sh
pnpm install
ruby -run -e httpd . -p 8000
```

If Ruby reports that `webrick` is not found, install it once with `gem install webrick`. Ruby 3.0 and later no longer include WEBrick as a standard library.

```text
http://localhost:8000/examples/browser/quickstart/
```

Use `http://localhost:8000/...`; do not open the files with `file://`, because the runtime loads ES modules, wasm, Ruby files, and assets over HTTP.

## When JavaScript Is Still Involved

The generated app still includes a JavaScript boot file. That file imports three.js, registers addon constructors, starts ruby.wasm, and loads the Ruby entrypoint. Application scene code should not need `require "js"` unless it reaches outside the current three-rb browser API into custom browser APIs, unwrapped three.js addons, or application-specific JavaScript integrations. Use `Three::Browser.js` for that explicit escape hatch and keep it isolated.
