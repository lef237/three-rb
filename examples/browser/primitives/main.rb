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
  status[:textContent] = "Starting primitives scene"

  scene = Three::Scene.new
  camera = Three::PerspectiveCamera.new(55, aspect: 1.0, near: 0.1, far: 100)
  camera.position.z = 4

  line_geometry = Three::BufferGeometry.new
  line_geometry.set_attribute(
    :position,
    Three::Float32BufferAttribute.new(
      [
        -1.8, -0.8, 0,
        -0.9, 0.75, 0,
        0.0, -0.15, 0,
        0.9, 0.75, 0,
        1.8, -0.8, 0
      ],
      3
    )
  )
  line = Three::Line.new(line_geometry, Three::LineBasicMaterial.new(color: 0x66ddff, linewidth: 2))

  points_geometry = Three::BufferGeometry.new
  points_geometry.set_attribute(
    :position,
    Three::Float32BufferAttribute.new(
      [
        -1.3, 0.25, 0.15,
        -0.65, -0.35, 0.25,
        0.0, 0.45, -0.2,
        0.65, -0.35, 0.25,
        1.3, 0.25, 0.15,
        0.0, -0.9, 0
      ],
      3
    )
  )
  points = Three::Points.new(
    points_geometry,
    Three::PointsMaterial.new(color: 0xffcc4d, size: 12, size_attenuation: false)
  )

  scene.add(line, points)

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
  JS.global[:__threeRbLine] = renderer.backend.materialize(line)
  JS.global[:__threeRbPoints] = renderer.backend.materialize(points)
  JS.global[:__threeRbPrimitivesFrame] = 0

  renderer.animation_loop do
    JS.global[:__threeRbPrimitivesFrame] = JS.global[:__threeRbPrimitivesFrame].to_i + 1
    line.rotation.z += 0.004
    points.rotation.y += 0.012
    renderer.render(scene, camera)
  end

  status[:textContent] = "Running"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
