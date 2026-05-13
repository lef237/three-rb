# frozen_string_literal: true

require "js"

JS.global[:__threeReady].await

require_relative "../../../lib/three"

document = JS.global[:document]
window = JS.global[:window]
viewport = document.call(:querySelector, "#viewport")
status = document.call(:querySelector, "#status")
status_dot = document.call(:querySelector, "#status-dot")

scene = Three::Scene.new
camera = Three::PerspectiveCamera.new(70, aspect: 1.0, near: 0.1, far: 100)
camera.position.z = 3

geometry = Three::BoxGeometry.new(1, 1, 1)
material = Three::MeshBasicMaterial.new(color: 0x4ed08f)
cube = Three::Mesh.new(geometry, material)
scene.add(cube)

renderer = Three::Renderers::ThreeJSRenderer.new(canvas: "#scene", antialias: true, alpha: true)

resize = proc do
  width = [viewport[:clientWidth].to_i, 1].max
  height = [viewport[:clientHeight].to_i, 1].max

  camera.aspect = width.to_f / height
  camera.update_projection_matrix
  renderer.set_size(width, height)
end

resize.call
window.call(:addEventListener, "resize", resize)

renderer.animation_loop do
  cube.rotation.x += 0.01
  cube.rotation.y += 0.015
  renderer.render(scene, camera)
end

status[:textContent] = "Running"
status_dot[:dataset][:state] = "running"
