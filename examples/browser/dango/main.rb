# frozen_string_literal: true

require_relative "../../../lib/three"

def dango_ring_points(radial_segments)
  (0..radial_segments).map do |index|
    angle = (Math::PI * 2 * index) / radial_segments
    [Math.cos(angle), Math.sin(angle), index.to_f / radial_segments]
  end
end

def append_dango_skewer_body(vertices, normals, uvs, indices, half_length, radius, ring_points)
  ring_points.each do |cosine, sine, u|
    y = cosine * radius
    z = sine * radius

    vertices.push(-half_length, y, z, half_length, y, z)
    normals.push(0, cosine, sine, 0, cosine, sine)
    uvs.push(u, 0, u, 1)
  end

  (ring_points.length - 1).times do |index|
    left = index * 2
    right = left + 1
    next_left = left + 2
    next_right = left + 3
    indices.push(left, next_left, right, right, next_left, next_right)
  end
end

def append_dango_skewer_cap(vertices, normals, uvs, indices, x, radius, ring_points, normal_x:, reverse: false)
  center = vertices.length / 3
  vertices.push(x, 0, 0)
  normals.push(normal_x, 0, 0)
  uvs.push(0.5, 0.5)

  ring_points.each do |cosine, sine, _u|
    vertices.push(x, cosine * radius, sine * radius)
    normals.push(normal_x, 0, 0)
    uvs.push((cosine + 1) / 2.0, (sine + 1) / 2.0)
  end

  (ring_points.length - 1).times do |index|
    first = center + index + 1
    second = center + index + 2
    reverse ? indices.push(center, second, first) : indices.push(center, first, second)
  end
end

def dango_skewer_geometry(length, radius, radial_segments: 18)
  geometry = Three::BufferGeometry.new
  half_length = length / 2.0
  ring_points = dango_ring_points(radial_segments)
  vertices = []
  normals = []
  uvs = []
  indices = []

  append_dango_skewer_body(vertices, normals, uvs, indices, half_length, radius, ring_points)
  append_dango_skewer_cap(vertices, normals, uvs, indices, -half_length, radius, ring_points, normal_x: -1, reverse: true)
  append_dango_skewer_cap(vertices, normals, uvs, indices, half_length, radius, ring_points, normal_x: 1)

  geometry.set_index(indices)
  geometry.set_attribute(:position, Three::Float32BufferAttribute.new(vertices, 3))
  geometry.set_attribute(:normal, Three::Float32BufferAttribute.new(normals, 3))
  geometry.set_attribute(:uv, Three::Float32BufferAttribute.new(uvs, 2))
  geometry
end

def dango_plate_part(size, material, position: nil, cast_shadow: true)
  mesh = Three::Mesh.new(Three::BoxGeometry.new(*size), material)
  mesh.position.set(*position) if position
  mesh.cast_shadow = cast_shadow
  mesh.receive_shadow = true
  mesh
end

def dango_lights
  hemisphere_light = Three::HemisphereLight.new(0xfffbf2, 0xd7ddb8, 0.68)

  key_light = Three::DirectionalLight.new(0xffffff, 1.05)
  key_light.position.set(-2.4, 3.0, 5.2)
  key_light.cast_shadow = true
  key_light.shadow_map_size = [1024, 1024]
  key_light.shadow_bias = -0.00008
  key_light.set_shadow_camera(left: -3.6, right: 3.6, top: 2.4, bottom: -2.4, near: 0.5, far: 12)

  fill_light = Three::PointLight.new(0xffe6d0, 0.52, 7, 2)
  fill_light.position.set(2.6, -1.2, 3.0)

  { hemisphere: hemisphere_light, key: key_light, fill: fill_light }
end

def dango_shadow_catcher
  material = Three::ShadowMaterial.new(color: 0x8c806d, opacity: 0.12)
  mesh = Three::Mesh.new(Three::PlaneGeometry.new(6.0, 3.6), material)
  mesh.position.z = -0.72
  mesh.receive_shadow = true
  mesh
end

def dango_plate
  plate = Three::Group.new
  plate.name = "dango-plate"
  plate.position.set(0, -1.15, 0.04)
  plate.rotation.x = -0.52

  floor_material = Three::MeshLambertMaterial.new(color: 0xfff7ea)
  rim_material = Three::MeshLambertMaterial.new(color: 0xf1d8ad)
  foot_material = Three::MeshLambertMaterial.new(color: 0xd3b680)
  parts = {
    floor: dango_plate_part([3.72, 0.08, 0.82], floor_material, cast_shadow: false),
    front_rim: dango_plate_part([4.08, 0.14, 0.12], rim_material, position: [0, 0.055, -0.48]),
    back_rim: dango_plate_part([4.08, 0.14, 0.12], rim_material, position: [0, 0.055, 0.48]),
    left_rim: dango_plate_part([0.14, 0.14, 0.82], rim_material, position: [-1.98, 0.055, 0]),
    right_rim: dango_plate_part([0.14, 0.14, 0.82], rim_material, position: [1.98, 0.055, 0]),
    foot: dango_plate_part([2.72, 0.08, 0.34], foot_material, position: [0, -0.12, -0.04])
  }
  parts.each_value { |part| plate.add(part) }

  [plate, parts]
end

def dango_skewer_mesh(length, material, position)
  mesh = Three::Mesh.new(dango_skewer_geometry(length, 0.034), material)
  mesh.position.set(*position)
  mesh.cast_shadow = true
  mesh
end

def dango_skewer
  material = Three::MeshLambertMaterial.new(color: 0xcbb281)
  skewer = Three::Group.new
  skewer.name = "dango-skewer-rod"

  core = dango_skewer_mesh(2.58, material, [0, 0, 0.04])
  tip = dango_skewer_mesh(0.72, material, [1.82, 0, 0.04])
  skewer.add(core, tip)

  [skewer, core, tip]
end

def dango_mochi
  geometry = Three::SphereGeometry.new(0.56, width_segments: 96, height_segments: 48)
  [
    ["sakura", -0.98, 0xf8cfd7, 0xf4dce1],
    ["plain", 0.0, 0xfffaed, 0xe8dfc8],
    ["matcha", 0.98, 0xc0dca4, 0xddebd0]
  ].map do |name, x, color, specular|
    material = Three::MeshPhongMaterial.new(color: color, specular: specular, shininess: 14)
    mesh = Three::Mesh.new(geometry, material)
    mesh.name = "#{name}-dango"
    mesh.position.set(x, 0, 0.04)
    mesh.cast_shadow = true
    mesh.receive_shadow = true
    mesh
  end
end

def dango_skewer_group
  group = Three::Group.new
  group.name = "dango-skewer"
  group.rotation.z = -0.22
  group.position.set(0, 0.18, -0.75)
  group
end

def dango_renderer
  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true,
    shadow_map_enabled: true,
    shadow_map_type: Three::PCFSoftShadowMap
  )
  renderer.set_clear_color(0xfaf5ec, 1)
  renderer
end

def dango_controls(camera, renderer)
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
  controls
end

Three::Browser.run(starting: "Starting dango scene") do |app|
  scene = Three::Scene.new
  camera = Three::OrthographicCamera.new(-3.2, 3.2, 2.0, -2.0, near: 0.1, far: 100)
  camera.position.z = 6

  lights = dango_lights
  hemisphere_light = lights[:hemisphere]
  key_light = lights[:key]
  fill_light = lights[:fill]
  scene.add(hemisphere_light, key_light, fill_light)

  shadow_catcher = dango_shadow_catcher
  scene.add(shadow_catcher)

  plate, plate_parts = dango_plate
  scene.add(plate)

  dango_group = dango_skewer_group
  scene.add(dango_group)

  skewer, skewer_core, skewer_tip = dango_skewer
  dango_group.add(skewer)

  mochi = dango_mochi
  mochi.each { |mesh| dango_group.add(mesh) }

  renderer = dango_renderer
  controls = dango_controls(camera, renderer)

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
      dango_plate_floor: plate_parts[:floor],
      dango_plate_front_rim: plate_parts[:front_rim],
      dango_plate_back_rim: plate_parts[:back_rim],
      dango_plate_left_rim: plate_parts[:left_rim],
      dango_plate_right_rim: plate_parts[:right_rim],
      dango_plate_foot: plate_parts[:foot],
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
    dango_group.position.y = 0.18 + (Math.sin(frame * 0.03) * 0.02)
    plate.rotation.z = Math.sin(frame * 0.012) * 0.018

    controls.update
    renderer.render(scene, camera)
  end
end
