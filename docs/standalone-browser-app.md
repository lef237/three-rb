# Standalone Browser App

This guide shows how to make a small browser app outside the three-rb repository with your own Ruby entrypoint.

The current browser runtime is still alpha. A standalone app needs a small JavaScript boot file because the browser must start ruby.wasm, expose three.js constructors, and then load your Ruby file over HTTP.

## Create The App Directory

Install the gem, create a new app directory, and copy the runtime files from the installed gem:

```sh
mkdir hello-three-rb
cd hello-three-rb

gem install three-rb
gem_dir=$(ruby -e 'puts Gem::Specification.find_by_name("three-rb").full_gem_path')

cp "$gem_dir/package.json" "$gem_dir/pnpm-lock.yaml" .
cp -R "$gem_dir/lib" .
mkdir -p examples/browser/shared examples/browser/quickstart
cp "$gem_dir/examples/browser/shared/boot.mjs" examples/browser/shared/boot.mjs
cp "$gem_dir/examples/browser/cube/index.html" examples/browser/quickstart/index.html
```

If you installed through Bundler instead of `gem install`, use:

```sh
gem_dir=$(bundle show three-rb)
```

Copying `lib/` puts the installed gem's Ruby source in the served app directory. The browser Ruby VM loads Ruby files over HTTP, so this is the current standalone workflow.

## Add The Boot File

Create `examples/browser/quickstart/boot.mjs`:

```js
import { bootRubyExample } from "../shared/boot.mjs";

await bootRubyExample({
  main: "examples/browser/quickstart/main",
  clearColor: 0x101418
});
```

## Add Your Ruby Entrypoint

Create `examples/browser/quickstart/main.rb`:

```ruby
# frozen_string_literal: true

require "js"

JS.global[:__threeReady].await
require_relative "../../../lib/three"

document = JS.global[:document]
window = JS.global[:window]
viewport = document.call(:querySelector, "#viewport")
status = document.call(:querySelector, "#status")
status_dot = document.call(:querySelector, "#status-dot")

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

resize = proc do
  width = [viewport[:clientWidth].to_i, 1].max
  height = [viewport[:clientHeight].to_i, 1].max

  camera.aspect = width.to_f / height
  camera.update_projection_matrix
  renderer.set_size(width, height)
end

resize.call
window.call(:addEventListener, "resize", resize)

renderer.animation_loop do
  cube.rotation.x += 0.01
  cube.rotation.y += 0.015
  renderer.render(scene, camera)
end

status[:textContent] = "Running"
status_dot[:dataset][:state] = "running"
```

## Run It

Install browser packages, serve the app directory, and open the page:

```sh
pnpm install
ruby -run -e httpd . -p 8000
```

```text
http://localhost:8000/examples/browser/quickstart/
```

Use `http://localhost:8000/...`; do not open the files with `file://`, because the runtime loads ES modules, wasm, Ruby files, and assets over HTTP.
