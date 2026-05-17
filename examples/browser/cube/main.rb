# frozen_string_literal: true

require_relative "../../../lib/three"

Three::Browser.run(starting: "Starting Ruby scene") do |app|
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

  app.resize_renderer(renderer, camera)
  renderer.render(scene, camera)
  app.expose({ renderer: renderer, scene: scene, camera: camera, cube: cube }, renderer: renderer)

  renderer.animation_loop do
    cube.rotation.x += 0.01
    cube.rotation.y += 0.015
    renderer.render(scene, camera)
  end
end
