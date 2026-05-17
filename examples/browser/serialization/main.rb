# frozen_string_literal: true

require_relative "../../../lib/three"

Three::Browser.run(starting: "Exporting Ruby scene") do |app|
  source_scene = Three::Scene.new
  source_scene.name = "serialization-source"

  shared_texture = Three::Loaders::TextureLoader.new.load("/examples/browser/assets/checker.svg")
  shared_texture.wrap_s = Three::RepeatWrapping
  shared_texture.wrap_t = Three::RepeatWrapping
  shared_texture.mag_filter = Three::NearestFilter
  shared_texture.min_filter = Three::NearestMipmapNearestFilter
  shared_texture.repeat.set(2, 2)

  geometry = Three::BoxGeometry.new(0.82, 0.82, 0.82)
  material = Three::MeshBasicMaterial.new(color: 0xffffff, map: shared_texture)
  first = Three::Mesh.new(geometry, material)
  first.name = "loaded-left"
  first.position.x = -0.68

  second = Three::Mesh.new(geometry, material)
  second.name = "loaded-right"
  second.position.x = 0.68
  second.scale.set(0.72, 0.72, 0.72)

  source_scene.add(first, second)

  exported = Three::Exporters::ThreeJSONExporter.new(deterministic_ids: true).export(source_scene)
  json = JSON.generate(exported)
  scene = Three::Loaders::ThreeJSONLoader.new.parse(json)
  scene.name = "serialization-loaded"

  camera = Three::PerspectiveCamera.new(62, aspect: 1.0, near: 0.1, far: 100)
  camera.position.z = 3.4

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x101418, 1)

  app.resize_renderer(renderer, camera)
  renderer.render(scene, camera)

  left = scene.get_object_by_name("loaded-left")
  right = scene.get_object_by_name("loaded-right")

  app.expose(
    {
      renderer: renderer,
      scene: scene,
      camera: camera,
      serialized_json: json,
      loaded_left: left,
      loaded_right: right,
      loaded_shared_geometry: left.geometry.equal?(right.geometry),
      loaded_shared_material: left.material.equal?(right.material),
      loaded_shared_texture: left.material.map.equal?(right.material.map),
      serialization_frame: 0
    },
    renderer: renderer
  )

  renderer.animation_loop do
    app.increment(:serialization_frame)
    left.rotation.x += 0.012
    left.rotation.y += 0.018
    right.rotation.x -= 0.01
    right.rotation.y += 0.014
    renderer.render(scene, camera)
  end
end
