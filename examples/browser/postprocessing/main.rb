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
  status[:textContent] = "Starting postprocessing scene"

  scene = Three::Scene.new
  camera = Three::PerspectiveCamera.new(52, aspect: 1.0, near: 0.1, far: 100)
  camera.position.set(0, 0.15, 5.2)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x0a0d12, 1)

  composer = Three::Postprocessing::EffectComposer.new(renderer: renderer)
  render_pass = Three::Postprocessing::RenderPass.new(scene, camera, composer: composer)
  bloom_pass = Three::Postprocessing::UnrealBloomPass.new(
    resolution: [1, 1],
    strength: 1.15,
    radius: 0.42,
    threshold: 0.22,
    composer: composer
  )
  output_pass = Three::Postprocessing::OutputPass.new(composer: composer)
  composer.add_pass(render_pass)
  composer.add_pass(bloom_pass)
  composer.add_pass(output_pass)

  core_material = Three::MeshBasicMaterial.new(color: 0xf8fbff)
  core = Three::Mesh.new(Three::SphereGeometry.new(0.48, width_segments: 32, height_segments: 16), core_material)
  scene.add(core)

  ring_material = Three::MeshBasicMaterial.new(color: 0x4ed08f)
  ring = Three::Mesh.new(Three::BoxGeometry.new(2.15, 0.035, 0.035), ring_material)
  ring.position.z = -0.05
  scene.add(ring)

  accent_material = Three::MeshBasicMaterial.new(color: 0xffcc4d)
  left_accent = Three::Mesh.new(Three::BoxGeometry.new(0.18, 0.18, 0.18), accent_material)
  left_accent.position.set(-1.25, -0.52, 0.15)
  scene.add(left_accent)

  right_accent = Three::Mesh.new(Three::BoxGeometry.new(0.18, 0.18, 0.18), accent_material)
  right_accent.position.set(1.25, 0.52, 0.15)
  scene.add(right_accent)

  resize = proc do
    width = [viewport[:clientWidth].to_i, 1].max
    height = [viewport[:clientHeight].to_i, 1].max

    camera.aspect = width.to_f / height
    camera.update_projection_matrix
    renderer.set_size(width, height)
    composer.set_size(width, height)
  end

  resize.call
  window.call(:addEventListener, "resize", resize)
  composer.render(scene, camera)

  JS.global[:__threeRbRenderer] = renderer.handle
  JS.global[:__threeRbPostComposer] = composer.handle
  JS.global[:__threeRbPostRenderPass] = render_pass.handle
  JS.global[:__threeRbPostBloomPass] = bloom_pass.handle
  JS.global[:__threeRbPostOutputPass] = output_pass.handle
  JS.global[:__threeRbScene] = renderer.backend.materialize(scene)
  JS.global[:__threeRbCamera] = renderer.backend.materialize(camera)
  JS.global[:__threeRbPostCore] = renderer.backend.materialize(core)
  JS.global[:__threeRbPostRing] = renderer.backend.materialize(ring)
  JS.global[:__threeRbPostLeftAccent] = renderer.backend.materialize(left_accent)
  JS.global[:__threeRbPostRightAccent] = renderer.backend.materialize(right_accent)
  JS.global[:__threeRbPostFrame] = 0

  renderer.animation_loop do
    frame = JS.global[:__threeRbPostFrame].to_i + 1
    JS.global[:__threeRbPostFrame] = frame

    core.rotation.y += 0.014
    ring.rotation.z += 0.01
    left_accent.rotation.x += 0.018
    left_accent.rotation.y += 0.013
    right_accent.rotation.x -= 0.014
    right_accent.rotation.y += 0.017
    bloom_pass.strength = 0.95 + (0.22 * ((Math.sin(frame * 0.035) + 1) / 2.0))

    composer.render(scene, camera)
  end

  status[:textContent] = "Running"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
