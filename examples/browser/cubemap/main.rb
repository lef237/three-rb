# frozen_string_literal: true

require_relative "../../../lib/three"

Three::Browser.run(starting: "Starting Ruby scene") do |app|
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

  app.resize_renderer(renderer, camera)
  renderer.render(scene, camera)
  app.expose(
    {
      renderer: renderer,
      cubemap_scene: scene,
      camera: camera,
      cubemap_mesh: mesh,
      cubemap_material: material,
      cube_texture: cube_texture,
      cubemap_frame: 0
    },
    renderer: renderer
  )

  frame = 0
  renderer.animation_loop do
    frame += 1
    mesh.rotation.y += 0.01
    mesh.rotation.x = Math.sin(frame * 0.02) * 0.08
    app.set(:cubemap_frame, frame)
    renderer.render(scene, camera)
  end
end
