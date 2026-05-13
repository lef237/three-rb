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
  camera = Three::OrthographicCamera.new(-3, 3, 1.8, -1.8, near: 0.1, far: 100)
  camera.position.z = 5

  backdrop_material = Three::MeshBasicMaterial.new(color: 0x243141)
  backdrop = Three::Mesh.new(Three::PlaneGeometry.new(5.8, 3.4, width_segments: 2, height_segments: 2), backdrop_material)
  backdrop.position.z = -1.25
  scene.add(backdrop)

  rig = Three::Group.new
  rig.name = "composition-rig"
  scene.add(rig)

  primary_material = Three::MeshBasicMaterial.new(color: 0x61d394)
  primary = Three::Mesh.new(Three::BoxGeometry.new(0.85, 0.85, 0.85), primary_material)
  primary.position.x = -0.55
  primary.position.z = 0.15
  rig.add(primary)

  satellite_material = Three::MeshNormalMaterial.new(flat_shading: true)
  satellite = Three::Mesh.new(Three::BoxGeometry.new(0.42, 0.42, 0.42), satellite_material)
  satellite.position.x = 1.35
  satellite.position.y = -0.7
  satellite.position.z = 0.45
  rig.add(satellite)

  orb_material = Three::MeshBasicMaterial.new(color: 0x77a8ff)
  orb = Three::Mesh.new(Three::SphereGeometry.new(0.24, width_segments: 16, height_segments: 8), orb_material)
  orb.position.x = 0.25
  orb.position.y = 0.9
  orb.position.z = 0.35
  rig.add(orb)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x0f1419, 1)

  resize = proc do
    width = [viewport[:clientWidth].to_i, 1].max
    height = [viewport[:clientHeight].to_i, 1].max
    view_height = 3.8
    view_width = view_height * width.to_f / height

    camera.left = -view_width / 2
    camera.right = view_width / 2
    camera.top = view_height / 2
    camera.bottom = -view_height / 2
    camera.update_projection_matrix
    renderer.set_size(width, height)
  end

  resize.call
  window.call(:addEventListener, "resize", resize)
  renderer.render(scene, camera)

  JS.global[:__threeRbRenderer] = renderer.handle
  JS.global[:__threeRbScene] = renderer.backend.materialize(scene)
  JS.global[:__threeRbCamera] = renderer.backend.materialize(camera)
  JS.global[:__threeRbPlane] = renderer.backend.materialize(backdrop)
  JS.global[:__threeRbRig] = renderer.backend.materialize(rig)
  JS.global[:__threeRbPrimaryMesh] = renderer.backend.materialize(primary)
  JS.global[:__threeRbSatelliteMesh] = renderer.backend.materialize(satellite)
  JS.global[:__threeRbSphereMesh] = renderer.backend.materialize(orb)
  JS.global[:__threeRbChangingMaterial] = renderer.backend.materialize(primary_material)
  JS.global[:__threeRbNormalMaterial] = renderer.backend.materialize(satellite_material)
  JS.global[:__threeRbInitialMaterialColor] = primary_material.color.hex
  JS.global[:__threeRbCompositionFrame] = 0

  frame = 0
  renderer.animation_loop do
    frame += 1
    rig.rotation.z += 0.008
    primary.rotation.x += 0.017
    primary.rotation.y += 0.009
    satellite.rotation.y -= 0.025
    orb.rotation.x += 0.018
    orb.rotation.y -= 0.013

    pulse = (Math.sin(frame * 0.045) + 1) / 2.0
    primary_material.color.set_rgb(0.25 + (0.35 * pulse), 0.55 + (0.25 * pulse), 0.42)

    JS.global[:__threeRbCompositionFrame] = frame
    renderer.render(scene, camera)
  end

  status[:textContent] = "Running"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
