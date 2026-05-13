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

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x11151a, 1)

  gltf = Three::Loaders::GLTFLoader.new(backend: renderer.backend).load("/examples/browser/assets/animated_triangle.gltf")
  model = gltf.scene
  model.scale.set(1.2, 1.2, 1.2)
  scene.add(model)

  clock = Three::Clock.new
  mixer = Three::AnimationMixer.new(model, backend: renderer.backend)
  action = mixer.clip_action(gltf.animations.first)
  action.play

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
  JS.global[:__threeRbGltfAnimations] = gltf.animations.length
  JS.global[:__threeRbGltfAnimationName] = gltf.animations.first&.name
  JS.global[:__threeRbGltfAnimationDuration] = gltf.animations.first&.duration
  JS.global[:__threeRbGltfMixer] = mixer.handle
  JS.global[:__threeRbGltfAction] = action.handle
  JS.global[:__threeRbGltfFrame] = 0
  JS.global[:__threeRbGltfAnimationTime] = 0
  JS.global[:__threeRbDisposeGltf] = proc do
    mixer.stop_all_action
    mixer.uncache_root
    renderer.dispose_subtree(model, remove: true, dispose_textures: true)
    JS.global[:__threeRbGltfDisposed] = true
  end

  frame = 0
  renderer.animation_loop do
    frame += 1
    delta = clock.get_delta
    mixer.update(delta)
    JS.global[:__threeRbGltfAnimationTime] = JS.global[:__threeRbGltfAnimationTime].to_f + delta
    JS.global[:__threeRbGltfFrame] = frame
    renderer.render(scene, camera)
  end

  status[:textContent] = "Running"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
