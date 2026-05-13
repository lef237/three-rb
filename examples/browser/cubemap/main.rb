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
  camera.position.set(0, 0.7, 4.0)

  cube_sources = Array.new(6, "/examples/browser/assets/checker.svg")
  cube_texture = Three::Loaders::CubeTextureLoader.new.load(cube_sources)
  scene.background = cube_texture
  scene.environment = cube_texture

  scene.add(Three::AmbientLight.new(0xffffff, 0.3))

  key_light = Three::DirectionalLight.new(0xffffff, 1.2)
  key_light.position.set(3.0, 4.0, 5.0)
  scene.add(key_light)

  material = Three::MeshStandardMaterial.new(
    color: 0xf4f1e8,
    roughness: 0.18,
    metalness: 0.38
  )
  mesh = Three::Mesh.new(Three::SphereGeometry.new(1.05, width_segments: 32, height_segments: 18), material)
  mesh.rotation.y = 0.4
  scene.add(mesh)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x10151b, 1)

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
  JS.global[:__threeRbCubemapScene] = renderer.backend.materialize(scene)
  JS.global[:__threeRbCamera] = renderer.backend.materialize(camera)
  JS.global[:__threeRbCubemapMesh] = renderer.backend.materialize(mesh)
  JS.global[:__threeRbCubemapMaterial] = renderer.backend.materialize(material)
  JS.global[:__threeRbCubeTexture] = renderer.backend.materialize(cube_texture)
  JS.global[:__threeRbCubemapFrame] = 0

  frame = 0
  renderer.animation_loop do
    frame += 1
    mesh.rotation.y += 0.01
    mesh.rotation.x = Math.sin(frame * 0.02) * 0.08
    JS.global[:__threeRbCubemapFrame] = frame
    renderer.render(scene, camera)
  end

  status[:textContent] = "Running"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
