# frozen_string_literal: true

require "js"

begin
  JS.global[:__threeReady].await

  require_relative "../../../lib/three"

  document = JS.global[:document]
  window = JS.global[:window]
  viewport = document.call(:querySelector, "#viewport")
  status = document.call(:querySelector, "#status")
  status_dot = document.call(:querySelector, "#status-dot")
  status[:textContent] = "Starting Ruby scene"

  scene = Three::Scene.new
  camera = Three::PerspectiveCamera.new(45, aspect: 1.0, near: 0.1, far: 100)
  camera.position.set(0, 0.15, 4.0)

  scene.add(Three::AmbientLight.new(0xffffff, 0.65))

  key_light = Three::DirectionalLight.new(0xffffff, 1.0)
  key_light.position.set(2.5, 3.0, 4.0)
  scene.add(key_light)

  gltf = Three::Loaders::GLTFLoader.new.load("/examples/browser/assets/triangle.gltf")
  model = gltf.scene
  model.scale.set(1.2, 1.2, 1.2)
  scene.add(model)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x11151a, 1)

  resize = proc do
    width = [viewport[:clientWidth].to_i, 1].max
    height = [viewport[:clientHeight].to_i, 1].max

    camera.aspect = width.to_f / height
    camera.update_projection_matrix
    renderer.set_size(width, height)
  end

  resize.call
  window.call(:addEventListener, "resize", resize)
  renderer.render(scene, camera)

  JS.global[:__threeRbRenderer] = renderer.handle
  JS.global[:__threeRbGltfRootScene] = renderer.backend.materialize(scene)
  JS.global[:__threeRbCamera] = renderer.backend.materialize(camera)
  JS.global[:__threeRbGltfScene] = renderer.backend.materialize(model)
  JS.global[:__threeRbGltfFrame] = 0
  JS.global[:__threeRbDisposeGltf] = proc do
    renderer.dispose_subtree(model, remove: true, dispose_textures: true)
    JS.global[:__threeRbGltfDisposed] = true
  end

  frame = 0
  renderer.animation_loop do
    frame += 1
    model.rotation.y += 0.012
    JS.global[:__threeRbGltfFrame] = frame
    renderer.render(scene, camera)
  end

  status[:textContent] = "Running"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
