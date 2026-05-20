# frozen_string_literal: true

require_relative "../../../lib/three"

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
  plate.position.set(0, -1.1, -0.43)
  scene.add(plate)

  plate_rim_material = Three::MeshLambertMaterial.new(color: 0xf4ddb8)
  plate_rim = Three::Mesh.new(Three::SphereGeometry.new(1.0, width_segments: 64, height_segments: 16), plate_rim_material)
  plate_rim.scale.set(2.12, 0.22, 0.14)
  plate_rim.cast_shadow = true
  plate_rim.receive_shadow = true
  plate.add(plate_rim)

  plate_well_material = Three::MeshLambertMaterial.new(color: 0xfff6e6)
  plate_well = Three::Mesh.new(Three::SphereGeometry.new(1.0, width_segments: 64, height_segments: 12), plate_well_material)
  plate_well.position.set(0, 0.065, 0.12)
  plate_well.scale.set(1.58, 0.085, 0.055)
  plate_well.receive_shadow = true
  plate.add(plate_well)

  plate_foot_material = Three::MeshLambertMaterial.new(color: 0xd8bd90)
  plate_foot = Three::Mesh.new(Three::BoxGeometry.new(2.34, 0.085, 0.16), plate_foot_material)
  plate_foot.position.set(0, -0.205, -0.055)
  plate_foot.cast_shadow = true
  plate_foot.receive_shadow = true
  plate.add(plate_foot)

  dango_group = Three::Group.new
  dango_group.name = "dango-skewer"
  dango_group.rotation.z = -0.34
  dango_group.position.y = 0.32
  scene.add(dango_group)

  skewer_material = Three::MeshLambertMaterial.new(color: 0xcbb281)
  skewer = Three::Mesh.new(Three::BoxGeometry.new(3.64, 0.06, 0.06), skewer_material)
  skewer.position.set(0.34, 0, -0.22)
  skewer.cast_shadow = true
  dango_group.add(skewer)

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
    auto_rotate: true,
    auto_rotate_speed: 0.55,
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
      dango_mochi: mochi,
      dango_plate: plate,
      dango_plate_rim: plate_rim,
      dango_plate_well: plate_well,
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
    dango_group.rotation.y = Math.sin(frame * 0.025) * 0.18
    dango_group.rotation.x = -0.05 + (Math.sin(frame * 0.017) * 0.035)
    dango_group.position.y = 0.32 + (Math.sin(frame * 0.03) * 0.035)
    plate.rotation.z = Math.sin(frame * 0.012) * 0.018

    controls.update
    renderer.render(scene, camera)
  end
end
