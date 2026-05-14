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
  camera = Three::OrthographicCamera.new(-2.5, 2.5, 1.6, -1.6, near: 0.1, far: 100)
  camera.position.z = 5

  environment_texture = Three::Loaders::RGBELoader.new.load("/examples/browser/assets/studio.hdr")
  scene.environment = environment_texture

  scene.add(Three::AmbientLight.new(0xffffff, 0.45))

  key_light = Three::DirectionalLight.new(0xffffff, 1.1)
  key_light.position.set(2.5, 3.0, 4.0)
  scene.add(key_light)

  texture = Three::Loaders::TextureLoader.new.load("/examples/browser/assets/checker.svg")
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

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x11161a, 1)

  resize = proc do
    width = [viewport[:clientWidth].to_i, 1].max
    height = [viewport[:clientHeight].to_i, 1].max
    view_height = 3.4
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
  JS.global[:__threeRbTexturedMesh] = renderer.backend.materialize(mesh)
  JS.global[:__threeRbTextureMaterial] = renderer.backend.materialize(material)
  JS.global[:__threeRbMatcapMesh] = renderer.backend.materialize(matcap_mesh)
  JS.global[:__threeRbMatcapMaterial] = renderer.backend.materialize(matcap_material)
  JS.global[:__threeRbTextureExampleTexture] = renderer.backend.materialize(texture)
  JS.global[:__threeRbTextureExampleEnvironment] = renderer.backend.materialize(environment_texture)
  JS.global[:__threeRbTextureExampleFrame] = 0

  frame = 0
  renderer.animation_loop do
    frame += 1
    mesh.rotation.x -= 0.006
    mesh.rotation.y += 0.011
    matcap_mesh.rotation.x += 0.005
    matcap_mesh.rotation.y -= 0.009
    JS.global[:__threeRbTextureExampleFrame] = frame
    renderer.render(scene, camera)
  end

  status[:textContent] = "Running"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
