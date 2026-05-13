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
  camera = Three::PerspectiveCamera.new(70, aspect: 1.0, near: 0.1, far: 100)
  camera.position.z = 3

  geometry = Three::BoxGeometry.new(1, 1, 1)
  material = Three::MeshBasicMaterial.new(color: 0x4ed08f)
  cube = Three::Mesh.new(geometry, material)
  scene.add(cube)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
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
  renderer.render(scene, camera)
  JS.global[:__threeRbRenderer] = renderer.handle
  JS.global[:__threeRbScene] = renderer.backend.materialize(scene)
  JS.global[:__threeRbCamera] = renderer.backend.materialize(camera)
  JS.global[:__threeRbCube] = renderer.backend.materialize(cube)

  renderer.animation_loop do
    cube.rotation.x += 0.01
    cube.rotation.y += 0.015
    renderer.render(scene, camera)
  end

  status[:textContent] = "Running"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
