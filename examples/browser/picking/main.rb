# frozen_string_literal: true

require_relative "../../../lib/three"

Three::Browser.run(starting: "Starting picking scene") do |app|
  scene = Three::Scene.new
  camera = Three::PerspectiveCamera.new(60, aspect: 1.0, near: 0.1, far: 100)
  camera.position.z = 4

  geometry = Three::BoxGeometry.new(0.82, 0.82, 0.82)
  idle_color = 0x4ed08f
  picked_color = 0xffcc4d

  left_material = Three::MeshBasicMaterial.new(color: idle_color)
  right_material = Three::MeshBasicMaterial.new(color: idle_color)
  left_cube = Three::Mesh.new(geometry, left_material)
  left_cube.name = "left-cube"
  left_cube.position.x = -0.75
  right_cube = Three::Mesh.new(geometry, right_material)
  right_cube.name = "right-cube"
  right_cube.position.x = 0.75
  scene.add(left_cube, right_cube)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x101418, 1)

  pointer = Three::Vector2.new
  raycaster = Three::Raycaster.new(backend: renderer.backend)
  pickables = [left_cube, right_cube]
  selected = nil

  app.resize_renderer(renderer, camera)
  canvas = app.element(renderer.dom_element)
  canvas.on("click") do |event|
    pointer.set(*canvas.pointer_ndc(event))
    raycaster.set_from_camera(pointer, camera)
    hits = raycaster.intersect_objects(pickables, recursive: false)
    hit = hits.find(&:object)

    if selected
      selected.material.color.set_hex(idle_color)
      selected = nil
    end

    if hit
      selected = hit.object
      selected.material.color.set_hex(picked_color)
      app.set(:picked_name, selected.name)
      app.set(:picked_distance, hit.distance)
      app.set(:picked_point, hit.point.to_a)
    else
      app.set(:picked_name, nil)
      app.set(:picked_distance, nil)
      app.set(:picked_point, nil)
    end

    app.increment(:pick_count)
    renderer.render(scene, camera)
  end
  renderer.render(scene, camera)

  app.expose(
    {
      renderer: renderer,
      scene: scene,
      camera: camera,
      left_cube: left_cube,
      right_cube: right_cube,
      raycaster: raycaster,
      pick_count: 0,
      picking_frame: 0
    },
    renderer: renderer
  )

  renderer.animation_loop do
    app.increment(:picking_frame)
    left_cube.rotation.y += 0.01
    right_cube.rotation.y -= 0.01
    renderer.render(scene, camera)
  end
end
