# frozen_string_literal: true

require_relative "../../../lib/three"

Three::Browser.run(starting: "Starting Ruby scene") do |app|
  scene = Three::Scene.new
  camera = Three::OrthographicCamera.new(-2.5, 2.5, 1.6, -1.6, near: 0.1, far: 100)
  camera.position.z = 5

  environment_texture = Three::Loaders::RGBELoader.new.load("/examples/browser/textures/assets/studio.hdr")
  scene.environment = environment_texture

  scene.add(Three::AmbientLight.new(0xffffff, 0.45))

  key_light = Three::DirectionalLight.new(0xffffff, 1.1)
  key_light.position.set(2.5, 3.0, 4.0)
  scene.add(key_light)

  texture = Three::Loaders::TextureLoader.new.load("/examples/browser/textures/assets/checker.svg")
  texture.wrap_s = Three::RepeatWrapping
  texture.wrap_t = Three::RepeatWrapping
  texture.mag_filter = Three::NearestFilter
  texture.min_filter = Three::NearestMipmapNearestFilter
  texture.offset.set(0.125, 0.25)
  texture.repeat.set(4, 3)
  texture.center.set(0.5, 0.5)
  texture.rotation = 0.35

  material = Three::MeshPhysicalMaterial.new(
    color: 0xffffff,
    roughness: 0.42,
    metalness: 0.08,
    anisotropy: 0.25,
    anisotropy_rotation: 0.15,
    clearcoat: 0.65,
    clearcoat_roughness: 0.18,
    ior: 1.45,
    specular_intensity: 0.75,
    specular_color: 0xe8f1ff,
    map: texture,
    roughness_map: texture,
    metalness_map: texture,
    anisotropy_map: texture,
    clearcoat_map: texture
  )
  mesh = Three::Mesh.new(Three::BoxGeometry.new(1.8, 1.15, 0.32), material)
  mesh.position.x = -0.75
  mesh.rotation.x = -0.25
  mesh.rotation.y = 0.38
  scene.add(mesh)

  matcap_material = Three::MeshMatcapMaterial.new(color: 0xffffff, matcap: texture, map: texture, flat_shading: true)
  matcap_mesh = Three::Mesh.new(
    Three::SphereGeometry.new(0.52, width_segments: 32, height_segments: 16),
    matcap_material
  )
  matcap_mesh.position.x = 1.35
  matcap_mesh.rotation.y = -0.28
  scene.add(matcap_mesh)

  toon_material = Three::MeshToonMaterial.new(
    color: 0xf6c85f,
    emissive: 0x101820,
    map: texture,
    gradient_map: texture,
    flat_shading: true
  )
  toon_mesh = Three::Mesh.new(
    Three::SphereGeometry.new(0.42, width_segments: 24, height_segments: 12),
    toon_material
  )
  toon_mesh.position.set(0.32, -0.9, 0.18)
  scene.add(toon_mesh)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x11161a, 1)

  app.resize_renderer(renderer, camera) do |width, height, _aspect|
    view_height = 3.4
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
      scene: scene,
      camera: camera,
      textured_mesh: mesh,
      texture_material: material,
      matcap_mesh: matcap_mesh,
      matcap_material: matcap_material,
      toon_mesh: toon_mesh,
      toon_material: toon_material,
      texture_example_texture: texture,
      texture_example_environment: environment_texture,
      texture_example_frame: 0
    },
    renderer: renderer
  )

  frame = 0
  renderer.animation_loop do
    frame += 1
    mesh.rotation.x -= 0.006
    mesh.rotation.y += 0.011
    matcap_mesh.rotation.x += 0.005
    matcap_mesh.rotation.y -= 0.009
    toon_mesh.rotation.y += 0.012
    app.set(:texture_example_frame, frame)
    renderer.render(scene, camera)
  end
end
