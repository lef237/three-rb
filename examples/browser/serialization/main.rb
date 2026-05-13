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
  status[:textContent] = "Exporting Ruby scene"

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

  left = scene.get_object_by_name("loaded-left")
  right = scene.get_object_by_name("loaded-right")

  JS.global[:__threeRbRenderer] = renderer.handle
  JS.global[:__threeRbScene] = renderer.backend.materialize(scene)
  JS.global[:__threeRbCamera] = renderer.backend.materialize(camera)
  JS.global[:__threeRbSerializedJson] = json
  JS.global[:__threeRbLoadedLeft] = renderer.backend.materialize(left)
  JS.global[:__threeRbLoadedRight] = renderer.backend.materialize(right)
  JS.global[:__threeRbLoadedSharedGeometry] = left.geometry.equal?(right.geometry)
  JS.global[:__threeRbLoadedSharedMaterial] = left.material.equal?(right.material)
  JS.global[:__threeRbLoadedSharedTexture] = left.material.map.equal?(right.material.map)
  JS.global[:__threeRbSerializationFrame] = 0

  renderer.animation_loop do
    JS.global[:__threeRbSerializationFrame] = JS.global[:__threeRbSerializationFrame].to_i + 1
    left.rotation.x += 0.012
    left.rotation.y += 0.018
    right.rotation.x -= 0.01
    right.rotation.y += 0.014
    renderer.render(scene, camera)
  end

  status[:textContent] = "Running"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
