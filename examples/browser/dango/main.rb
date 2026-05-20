# frozen_string_literal: true

require_relative "../../../lib/three"

Three::Browser.run(starting: "Starting dango scene") do |app|
  scene = Three::Scene.new
  camera = Three::OrthographicCamera.new(-3.2, 3.2, 2.0, -2.0, near: 0.1, far: 100)
  camera.position.z = 6

  hemisphere_light = Three::HemisphereLight.new(0xfffbf2, 0x9dad7f, 0.56)
  scene.add(hemisphere_light)

  key_light = Three::DirectionalLight.new(0xffffff, 1.25)
  key_light.position.set(-2.4, 3.0, 5.2)
  key_light.cast_shadow = true
  key_light.shadow_map_size = [1024, 1024]
  key_light.shadow_bias = -0.00008
  key_light.set_shadow_camera(left: -3.6, right: 3.6, top: 2.4, bottom: -2.4, near: 0.5, far: 12)
  scene.add(key_light)

  fill_light = Three::PointLight.new(0xffd0b0, 0.45, 7, 2)
  fill_light.position.set(2.6, -1.2, 3.0)
  scene.add(fill_light)

  shadow_material = Three::ShadowMaterial.new(color: 0x6b5a45, opacity: 0.18)
  shadow_catcher = Three::Mesh.new(Three::PlaneGeometry.new(6.0, 3.6), shadow_material)
  shadow_catcher.position.z = -0.72
  shadow_catcher.receive_shadow = true
  scene.add(shadow_catcher)

  plate_material = Three::MeshLambertMaterial.new(color: 0xc9a66b)
  plate = Three::Mesh.new(Three::BoxGeometry.new(4.45, 0.16, 0.28), plate_material)
  plate.position.set(0, -1.16, -0.34)
  plate.cast_shadow = true
  plate.receive_shadow = true
  scene.add(plate)

  dango_group = Three::Group.new
  dango_group.name = "dango-skewer"
  dango_group.rotation.z = -0.34
  dango_group.position.y = 0.12
  scene.add(dango_group)

  skewer_material = Three::MeshLambertMaterial.new(color: 0xb48950)
  skewer = Three::Mesh.new(Three::BoxGeometry.new(5.35, 0.075, 0.075), skewer_material)
  skewer.position.z = -0.18
  skewer.cast_shadow = true
  dango_group.add(skewer)

  mochi_geometry = Three::SphereGeometry.new(0.58, width_segments: 48, height_segments: 24)
  mochi_specs = [
    { name: "sakura", x: -0.98, color: 0xf3a6b8, specular: 0xffcad2 },
    { name: "plain", x: 0.0, color: 0xf8f3e5, specular: 0xe0d8c8 },
    { name: "matcha", x: 0.98, color: 0x88b96a, specular: 0xc9e0b8 }
  ]
  mochi = mochi_specs.map do |spec|
    material = Three::MeshPhongMaterial.new(
      color: spec[:color],
      specular: spec[:specular],
      shininess: 24
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
  renderer.set_clear_color(0xf4efe5, 1)

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
  controls.target.set(0, -0.08, 0)

  app.resize_renderer(renderer, camera) do |width, height, _aspect|
    view_height = 4.05
    view_width = view_height * width.to_f / height

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
    dango_group.position.y = 0.12 + (Math.sin(frame * 0.03) * 0.035)
    plate.rotation.z = Math.sin(frame * 0.012) * 0.018

    controls.update
    renderer.render(scene, camera)
  end
end
