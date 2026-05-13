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
  status[:textContent] = "Starting picking scene"

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

  resize = proc do
    width = [viewport[:clientWidth].to_i, 1].max
    height = [viewport[:clientHeight].to_i, 1].max

    camera.aspect = width.to_f / height
    camera.update_projection_matrix
    renderer.set_size(width, height)
  end

  pointer = Three::Vector2.new
  raycaster = Three::Raycaster.new(backend: renderer.backend)
  pickables = [left_cube, right_cube]
  selected = nil

  pick = proc do |event|
    rect = renderer.dom_element.call(:getBoundingClientRect)
    x = ((event[:clientX].to_f - rect[:left].to_f) / rect[:width].to_f) * 2 - 1
    y = -(((event[:clientY].to_f - rect[:top].to_f) / rect[:height].to_f) * 2 - 1)
    pointer.set(x, y)
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
      JS.global[:__threeRbPickedName] = selected.name
      JS.global[:__threeRbPickedDistance] = hit.distance
      JS.global[:__threeRbPickedPoint] = hit.point.to_a
    else
      JS.global[:__threeRbPickedName] = nil
      JS.global[:__threeRbPickedDistance] = nil
      JS.global[:__threeRbPickedPoint] = nil
    end

    JS.global[:__threeRbPickCount] = JS.global[:__threeRbPickCount].to_i + 1
    renderer.render(scene, camera)
  end

  resize.call
  window.call(:addEventListener, "resize", resize)
  renderer.dom_element.call(:addEventListener, "click", pick)
  renderer.render(scene, camera)

  JS.global[:__threeRbRenderer] = renderer.handle
  JS.global[:__threeRbScene] = renderer.backend.materialize(scene)
  JS.global[:__threeRbCamera] = renderer.backend.materialize(camera)
  JS.global[:__threeRbLeftCube] = renderer.backend.materialize(left_cube)
  JS.global[:__threeRbRightCube] = renderer.backend.materialize(right_cube)
  JS.global[:__threeRbRaycaster] = raycaster.handle
  JS.global[:__threeRbPickCount] = 0
  JS.global[:__threeRbPickingFrame] = 0

  renderer.animation_loop do
    JS.global[:__threeRbPickingFrame] = JS.global[:__threeRbPickingFrame].to_i + 1
    left_cube.rotation.y += 0.01
    right_cube.rotation.y -= 0.01
    renderer.render(scene, camera)
  end

  status[:textContent] = "Running"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
