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

  ambient_light = Three::AmbientLight.new(0xffffff, 0.45)
  scene.add(ambient_light)

  key_light = Three::DirectionalLight.new(0xffffff, 1.35)
  key_light.position.set(2.5, 3.0, 4.5)
  key_light.cast_shadow = true
  key_light.shadow_map_size = [1024, 1024]
  key_light.shadow_bias = -0.0001
  key_light.set_shadow_camera(left: -3.2, right: 3.2, top: 2.4, bottom: -2.4, near: 0.2, far: 12)
  scene.add(key_light)

  point_light = Three::PointLight.new(0x77a8ff, 0.8, 7, 2)
  point_light.position.set(-1.6, 1.7, 2.4)
  scene.add(point_light)

  hemisphere_light = Three::HemisphereLight.new(0xdceeff, 0x1d2a20, 0.28)
  scene.add(hemisphere_light)

  backdrop_material = Three::MeshLambertMaterial.new(color: 0x243141)
  backdrop = Three::Mesh.new(Three::PlaneGeometry.new(5.8, 3.4, width_segments: 2, height_segments: 2), backdrop_material)
  backdrop.position.z = -1.25
  backdrop.receive_shadow = true
  scene.add(backdrop)

  shadow_material = Three::ShadowMaterial.new(color: 0x000000, opacity: 0.32)
  shadow_catcher = Three::Mesh.new(Three::PlaneGeometry.new(5.4, 3.0, width_segments: 1, height_segments: 1), shadow_material)
  shadow_catcher.position.z = -1.18
  shadow_catcher.receive_shadow = true
  scene.add(shadow_catcher)

  rig = Three::Group.new
  rig.name = "composition-rig"
  scene.add(rig)

  primary_texture = Three::Loaders::TextureLoader.new.load("/examples/browser/assets/checker.svg")
  primary_texture.wrap_s = Three::RepeatWrapping
  primary_texture.wrap_t = Three::RepeatWrapping
  primary_texture.mag_filter = Three::NearestFilter
  primary_texture.min_filter = Three::NearestMipmapNearestFilter
  primary_texture.repeat.set(2, 2)
  primary_material = Three::MeshLambertMaterial.new(color: 0xffffff, map: primary_texture)
  primary = Three::Mesh.new(Three::BoxGeometry.new(0.85, 0.85, 0.85), primary_material)
  primary.position.x = -0.55
  primary.position.z = 0.15
  primary.cast_shadow = true
  rig.add(primary)

  satellite_material = Three::MeshNormalMaterial.new(flat_shading: true)
  satellite = Three::Mesh.new(Three::BoxGeometry.new(0.42, 0.42, 0.42), satellite_material)
  satellite.position.x = 1.35
  satellite.position.y = -0.7
  satellite.position.z = 0.45
  satellite.cast_shadow = true
  rig.add(satellite)

  orb_material = Three::MeshStandardMaterial.new(color: 0x77a8ff, roughness: 0.38, metalness: 0.45)
  orb = Three::Mesh.new(Three::SphereGeometry.new(0.24, width_segments: 16, height_segments: 8), orb_material)
  orb.position.x = 0.25
  orb.position.y = 0.9
  orb.position.z = 0.35
  orb.cast_shadow = true
  rig.add(orb)

  highlight_material = Three::MeshPhongMaterial.new(
    color: 0xdce7ff,
    specular: 0xffffff,
    shininess: 72,
    specular_map: primary_texture
  )
  highlight = Three::Mesh.new(Three::SphereGeometry.new(0.18, width_segments: 12, height_segments: 8), highlight_material)
  highlight.position.x = -1.25
  highlight.position.y = 0.55
  highlight.position.z = 0.55
  highlight.cast_shadow = true
  rig.add(highlight)

  instance_count = 1000
  instance_columns = 50
  instanced_material = Three::MeshLambertMaterial.new(color: 0xffffff, opacity: 0.42, transparent: true)
  instanced_field = Three::InstancedMesh.new(Three::BoxGeometry.new(0.032, 0.032, 0.032), instanced_material, instance_count)
  instance_matrix = Three::Matrix4.new
  instance_count.times do |index|
    column = index % instance_columns
    row = index / instance_columns
    column_t = column.to_f / (instance_columns - 1)
    row_t = row.to_f / ((instance_count / instance_columns) - 1)
    x = (column - ((instance_columns - 1) / 2.0)) * 0.11
    y = (row - ((instance_count / instance_columns - 1) / 2.0)) * 0.12
    z = -0.85 - ((index % 7) * 0.012)
    instanced_field.set_matrix_at(index, instance_matrix.make_translation(x, y, z))
    instanced_field.set_color_at(index, [0.35 + (0.45 * column_t), 0.55 + (0.25 * row_t), 0.9 - (0.35 * column_t)])
  end
  scene.add(instanced_field)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true,
    shadow_map_enabled: true,
    shadow_map_type: Three::PCFShadowMap
  )
  renderer.set_clear_color(0x0f1419, 1)

  controls = Three::Controls::OrbitControls.new(
    camera,
    renderer: renderer,
    enable_damping: true,
    damping_factor: 0.08,
    enable_pan: false
  )
  controls.target.set(0, 0, 0)

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
  JS.global[:__threeRbControls] = controls.handle
  JS.global[:__threeRbScene] = renderer.backend.materialize(scene)
  JS.global[:__threeRbCamera] = renderer.backend.materialize(camera)
  JS.global[:__threeRbAmbientLight] = renderer.backend.materialize(ambient_light)
  JS.global[:__threeRbDirectionalLight] = renderer.backend.materialize(key_light)
  JS.global[:__threeRbPointLight] = renderer.backend.materialize(point_light)
  JS.global[:__threeRbHemisphereLight] = renderer.backend.materialize(hemisphere_light)
  JS.global[:__threeRbPlane] = renderer.backend.materialize(backdrop)
  JS.global[:__threeRbShadowCatcher] = renderer.backend.materialize(shadow_catcher)
  JS.global[:__threeRbShadowMaterial] = renderer.backend.materialize(shadow_material)
  JS.global[:__threeRbRig] = renderer.backend.materialize(rig)
  JS.global[:__threeRbPrimaryMesh] = renderer.backend.materialize(primary)
  JS.global[:__threeRbSatelliteMesh] = renderer.backend.materialize(satellite)
  JS.global[:__threeRbSphereMesh] = renderer.backend.materialize(orb)
  JS.global[:__threeRbPhongMesh] = renderer.backend.materialize(highlight)
  JS.global[:__threeRbInstancedMesh] = renderer.backend.materialize(instanced_field)
  JS.global[:__threeRbInstancedMaterial] = renderer.backend.materialize(instanced_material)
  JS.global[:__threeRbTexture] = renderer.backend.materialize(primary_texture)
  JS.global[:__threeRbChangingMaterial] = renderer.backend.materialize(primary_material)
  JS.global[:__threeRbLambertMaterial] = renderer.backend.materialize(primary_material)
  JS.global[:__threeRbNormalMaterial] = renderer.backend.materialize(satellite_material)
  JS.global[:__threeRbStandardMaterial] = renderer.backend.materialize(orb_material)
  JS.global[:__threeRbPhongMaterial] = renderer.backend.materialize(highlight_material)
  JS.global[:__threeRbMaterialDisposeEvent] = false
  JS.global[:__threeRbTextureDisposeEvent] = false

  disposable_texture = Three::Loaders::TextureLoader.new.load("/examples/browser/assets/checker.svg")
  disposable_material = Three::MeshBasicMaterial.new(map: disposable_texture)
  disposable_texture_handle = renderer.backend.materialize(disposable_texture)
  disposable_material_handle = renderer.backend.materialize(disposable_material)
  disposable_texture_handle.call(:addEventListener, "dispose", proc { JS.global[:__threeRbTextureDisposeEvent] = true })
  disposable_material_handle.call(:addEventListener, "dispose", proc { JS.global[:__threeRbMaterialDisposeEvent] = true })
  renderer.dispose(disposable_material, dispose_textures: true)
  JS.global[:__threeRbMaterialHandleCachedAfterDispose] = renderer.backend.handles.key?(disposable_material.uuid)
  JS.global[:__threeRbTextureHandleCachedAfterDispose] = renderer.backend.handles.key?(disposable_texture.uuid)
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
    highlight.rotation.y += 0.021
    instanced_field.rotation.z -= 0.0015

    pulse = (Math.sin(frame * 0.045) + 1) / 2.0
    primary_material.color.set_rgb(0.25 + (0.35 * pulse), 0.55 + (0.25 * pulse), 0.42)

    JS.global[:__threeRbCompositionFrame] = frame
    controls.update
    renderer.render(scene, camera)
  end

  status[:textContent] = "Running"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
