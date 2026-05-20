# frozen_string_literal: true

require_relative "../../../lib/three"

def dango_skewer_geometry(length, radius, radial_segments: 18)
  geometry = Three::BufferGeometry.new
  half_length = length / 2.0
  vertices = []
  normals = []
  uvs = []
  indices = []

  (radial_segments + 1).times do |index|
    angle = (Math::PI * 2 * index) / radial_segments
    y = Math.cos(angle) * radius
    z = Math.sin(angle) * radius
    normal_y = Math.cos(angle)
    normal_z = Math.sin(angle)

    vertices.push(-half_length, y, z, half_length, y, z)
    normals.push(0, normal_y, normal_z, 0, normal_y, normal_z)
    u = index.to_f / radial_segments
    uvs.push(u, 0, u, 1)
  end

  radial_segments.times do |index|
    left = index * 2
    right = left + 1
    next_left = left + 2
    next_right = left + 3
    indices.push(left, next_left, right, right, next_left, next_right)
  end

  left_center = vertices.length / 3
  vertices.push(-half_length, 0, 0)
  normals.push(-1, 0, 0)
  uvs.push(0.5, 0.5)
  (radial_segments + 1).times do |index|
    angle = (Math::PI * 2 * index) / radial_segments
    vertices.push(-half_length, Math.cos(angle) * radius, Math.sin(angle) * radius)
    normals.push(-1, 0, 0)
    uvs.push((Math.cos(angle) + 1) / 2.0, (Math.sin(angle) + 1) / 2.0)
  end
  radial_segments.times do |index|
    indices.push(left_center, left_center + index + 2, left_center + index + 1)
  end

  right_center = vertices.length / 3
  vertices.push(half_length, 0, 0)
  normals.push(1, 0, 0)
  uvs.push(0.5, 0.5)
  (radial_segments + 1).times do |index|
    angle = (Math::PI * 2 * index) / radial_segments
    vertices.push(half_length, Math.cos(angle) * radius, Math.sin(angle) * radius)
    normals.push(1, 0, 0)
    uvs.push((Math.cos(angle) + 1) / 2.0, (Math.sin(angle) + 1) / 2.0)
  end
  radial_segments.times do |index|
    indices.push(right_center, right_center + index + 1, right_center + index + 2)
  end

  geometry.set_index(indices)
  geometry.set_attribute(:position, Three::Float32BufferAttribute.new(vertices, 3))
  geometry.set_attribute(:normal, Three::Float32BufferAttribute.new(normals, 3))
  geometry.set_attribute(:uv, Three::Float32BufferAttribute.new(uvs, 2))
  geometry
end

Three::Browser.run(starting: "Starting dango scene") do |app|
  scene = Three::Scene.new
  camera = Three::OrthographicCamera.new(-3.2, 3.2, 2.0, -2.0, near: 0.1, far: 100)
  camera.position.z = 6

  hemisphere_light = Three::HemisphereLight.new(0xfffbf2, 0xd7ddb8, 0.68)
  scene.add(hemisphere_light)

  key_light = Three::DirectionalLight.new(0xffffff, 1.05)
  key_light.position.set(-2.4, 3.0, 5.2)
  key_light.cast_shadow = true
  key_light.shadow_map_size = [1024, 1024]
  key_light.shadow_bias = -0.00008
  key_light.set_shadow_camera(left: -3.6, right: 3.6, top: 2.4, bottom: -2.4, near: 0.5, far: 12)
  scene.add(key_light)

  fill_light = Three::PointLight.new(0xffe6d0, 0.52, 7, 2)
  fill_light.position.set(2.6, -1.2, 3.0)
  scene.add(fill_light)

  shadow_material = Three::ShadowMaterial.new(color: 0x8c806d, opacity: 0.12)
  shadow_catcher = Three::Mesh.new(Three::PlaneGeometry.new(6.0, 3.6), shadow_material)
  shadow_catcher.position.z = -0.72
  shadow_catcher.receive_shadow = true
  scene.add(shadow_catcher)

  plate = Three::Group.new
  plate.name = "dango-plate"
  plate.position.set(0, -1.15, -0.52)
  plate.rotation.x = -0.52
  scene.add(plate)

  plate_floor_material = Three::MeshLambertMaterial.new(color: 0xfff7ea)
  plate_floor = Three::Mesh.new(Three::BoxGeometry.new(3.72, 0.08, 0.82), plate_floor_material)
  plate_floor.receive_shadow = true
  plate.add(plate_floor)

  plate_rim_material = Three::MeshLambertMaterial.new(color: 0xf1d8ad)
  plate_front_rim = Three::Mesh.new(Three::BoxGeometry.new(4.08, 0.14, 0.12), plate_rim_material)
  plate_front_rim.position.set(0, 0.055, -0.48)
  plate_front_rim.cast_shadow = true
  plate_front_rim.receive_shadow = true
  plate.add(plate_front_rim)

  plate_back_rim = Three::Mesh.new(Three::BoxGeometry.new(4.08, 0.14, 0.12), plate_rim_material)
  plate_back_rim.position.set(0, 0.055, 0.48)
  plate_back_rim.cast_shadow = true
  plate_back_rim.receive_shadow = true
  plate.add(plate_back_rim)

  plate_left_rim = Three::Mesh.new(Three::BoxGeometry.new(0.14, 0.14, 0.82), plate_rim_material)
  plate_left_rim.position.set(-1.98, 0.055, 0)
  plate_left_rim.cast_shadow = true
  plate_left_rim.receive_shadow = true
  plate.add(plate_left_rim)

  plate_right_rim = Three::Mesh.new(Three::BoxGeometry.new(0.14, 0.14, 0.82), plate_rim_material)
  plate_right_rim.position.set(1.98, 0.055, 0)
  plate_right_rim.cast_shadow = true
  plate_right_rim.receive_shadow = true
  plate.add(plate_right_rim)

  plate_foot_material = Three::MeshLambertMaterial.new(color: 0xd3b680)
  plate_foot = Three::Mesh.new(Three::BoxGeometry.new(2.72, 0.08, 0.34), plate_foot_material)
  plate_foot.position.set(0, -0.12, -0.04)
  plate_foot.cast_shadow = true
  plate_foot.receive_shadow = true
  plate.add(plate_foot)

  dango_group = Three::Group.new
  dango_group.name = "dango-skewer"
  dango_group.rotation.z = -0.22
  dango_group.position.y = 0.32
  scene.add(dango_group)

  skewer_material = Three::MeshLambertMaterial.new(color: 0xcbb281)
  skewer = Three::Group.new
  skewer.name = "dango-skewer-rod"
  dango_group.add(skewer)

  skewer_core = Three::Mesh.new(dango_skewer_geometry(2.58, 0.034), skewer_material)
  skewer_core.position.z = 0.04
  skewer_core.cast_shadow = true
  skewer.add(skewer_core)

  skewer_tip = Three::Mesh.new(dango_skewer_geometry(0.72, 0.034), skewer_material)
  skewer_tip.position.x = 1.82
  skewer_tip.position.z = 0.04
  skewer_tip.cast_shadow = true
  skewer.add(skewer_tip)

  mochi_geometry = Three::SphereGeometry.new(0.58, width_segments: 48, height_segments: 24)
  mochi_specs = [
    { name: "sakura", x: -0.98, color: 0xf8cfd7, specular: 0xf4dce1 },
    { name: "plain", x: 0.0, color: 0xfffaed, specular: 0xe8dfc8 },
    { name: "matcha", x: 0.98, color: 0xc0dca4, specular: 0xddebd0 }
  ]
  mochi = mochi_specs.map do |spec|
    material = Three::MeshPhongMaterial.new(
      color: spec[:color],
      specular: spec[:specular],
      shininess: 14
    )
    mesh = Three::Mesh.new(mochi_geometry, material)
    mesh.name = "#{spec[:name]}-dango"
    mesh.position.set(spec[:x], 0, 0.04)
    mesh.scale.set(1.0, 0.96, 0.88)
    mesh.cast_shadow = true
    mesh.receive_shadow = true
    dango_group.add(mesh)
    mesh
  end

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true,
    shadow_map_enabled: true,
    shadow_map_type: Three::PCFSoftShadowMap
  )
  renderer.set_clear_color(0xfaf5ec, 1)

  controls = Three::Controls::OrbitControls.new(
    camera,
    renderer: renderer,
    enable_damping: true,
    damping_factor: 0.08,
    enable_pan: false,
    auto_rotate: false,
    min_zoom: 0.82,
    max_zoom: 1.65
  )
  controls.target.set(0, -0.18, 0)

  app.resize_renderer(renderer, camera) do |width, height, _aspect|
    view_height = 4.05
    view_width = view_height * width.to_f / height
    if view_width < 4.6
      view_width = 4.6
      view_height = view_width * height.to_f / width
    end

    camera.left = -view_width / 2
    camera.right = view_width / 2
    camera.top = view_height / 2
    camera.bottom = -view_height / 2
    camera.update_projection_matrix
  end
  renderer.render(scene, camera)

  app.expose(
    {
      renderer: renderer,
      controls: controls,
      scene: scene,
      camera: camera,
      dango_group: dango_group,
      dango_skewer: skewer,
      dango_skewer_core: skewer_core,
      dango_skewer_tip: skewer_tip,
      dango_mochi: mochi,
      dango_plate: plate,
      dango_plate_floor: plate_floor,
      dango_plate_front_rim: plate_front_rim,
      dango_plate_back_rim: plate_back_rim,
      dango_plate_left_rim: plate_left_rim,
      dango_plate_right_rim: plate_right_rim,
      dango_plate_foot: plate_foot,
      dango_shadow: shadow_catcher,
      dango_key_light: key_light,
      dango_hemisphere_light: hemisphere_light,
      dango_fill_light: fill_light,
      dango_frame: 0
    },
    renderer: renderer
  )

  renderer.animation_loop do
    frame = app.increment(:dango_frame)
    dango_group.rotation.y = 0
    dango_group.rotation.x = -0.05 + (Math.sin(frame * 0.017) * 0.035)
    dango_group.position.y = 0.32 + (Math.sin(frame * 0.03) * 0.035)
    plate.rotation.z = Math.sin(frame * 0.012) * 0.018

    controls.update
    renderer.render(scene, camera)
  end
end
