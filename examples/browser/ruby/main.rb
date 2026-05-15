# frozen_string_literal: true

require "js"

def gem_ring(radius, y, sides, offset)
  sides.times.map do |index|
    angle = offset + (Math::PI * 2 * index / sides)
    [Math.cos(angle) * radius, y, Math.sin(angle) * radius]
  end
end

def face_normal(a, b, c)
  ux = b[0] - a[0]
  uy = b[1] - a[1]
  uz = b[2] - a[2]
  vx = c[0] - a[0]
  vy = c[1] - a[1]
  vz = c[2] - a[2]
  nx = (uy * vz) - (uz * vy)
  ny = (uz * vx) - (ux * vz)
  nz = (ux * vy) - (uy * vx)
  length = Math.sqrt((nx * nx) + (ny * ny) + (nz * nz))
  return [0, 1, 0] if length.zero?

  [nx / length, ny / length, nz / length]
end

def add_triangle(vertices, normals, a, b, c)
  normal = face_normal(a, b, c)
  [a, b, c].each do |point|
    vertices.push(*point)
    normals.push(*normal)
  end
end

def add_polygon(vertices, normals, points)
  (1...(points.length - 1)).each do |index|
    add_triangle(vertices, normals, points[0], points[index], points[index + 1])
  end
end

def faceted_ruby_geometry
  sides = 10
  step = Math::PI * 2 / sides
  top = gem_ring(0.62, 0.58, sides, step / 2)
  crown = gem_ring(1.02, 0.18, sides, 0)
  girdle = gem_ring(1.15, -0.08, sides, step / 2)
  pavilion = gem_ring(0.64, -0.48, sides, 0)
  culet = [0, -1.05, 0]
  vertices = []
  normals = []

  add_polygon(vertices, normals, top.reverse)
  sides.times do |index|
    next_index = (index + 1) % sides
    add_polygon(vertices, normals, [top[index], top[next_index], crown[next_index], crown[index]])
    add_polygon(vertices, normals, [crown[index], crown[next_index], girdle[next_index], girdle[index]])
    add_polygon(vertices, normals, [girdle[index], girdle[next_index], pavilion[next_index], pavilion[index]])
    add_triangle(vertices, normals, pavilion[next_index], pavilion[index], culet)
  end

  geometry = Three::BufferGeometry.new
  geometry.set_attribute(:position, Three::Float32BufferAttribute.new(vertices, 3))
  geometry.set_attribute(:normal, Three::Float32BufferAttribute.new(normals, 3))
  geometry.compute_bounding_box
  geometry.compute_bounding_sphere
  geometry
end

def build_spark(size, material)
  spark = Three::Group.new
  spark.name = "ruby-spark"

  long_ray = Three::Mesh.new(Three::BoxGeometry.new(size, size * 0.08, size * 0.08), material)
  spark.add(long_ray)

  cross_ray = Three::Mesh.new(Three::BoxGeometry.new(size * 0.68, size * 0.065, size * 0.065), material)
  cross_ray.rotation.z = Math::PI / 2
  spark.add(cross_ray)

  slash_ray = Three::Mesh.new(Three::BoxGeometry.new(size * 0.52, size * 0.055, size * 0.055), material)
  slash_ray.rotation.z = Math::PI / 4
  spark.add(slash_ray)

  core = Three::Mesh.new(
    Three::SphereGeometry.new(size * 0.075, width_segments: 10, height_segments: 6),
    material
  )
  spark.add(core)
  spark
end

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
  camera = Three::PerspectiveCamera.new(42, aspect: 1.0, near: 0.1, far: 100)
  camera.position.set(0, 0.42, 6.9)

  environment_texture = Three::Loaders::RGBELoader.new.load("/examples/browser/assets/studio.hdr")
  scene.environment = environment_texture

  scene.add(Three::AmbientLight.new(0xffffff, 0.62))
  scene.add(Three::HemisphereLight.new(0xf7fbff, 0xffd7dd, 0.8))

  key_light = Three::DirectionalLight.new(0xffffff, 2.2)
  key_light.position.set(3.2, 4.4, 4.8)
  key_light.cast_shadow = true
  key_light.shadow_map_size = [1024, 1024]
  key_light.shadow_bias = -0.00008
  key_light.set_shadow_camera(left: -3.2, right: 3.2, top: 2.6, bottom: -2.6, near: 0.2, far: 12)
  scene.add(key_light)

  rim_light = Three::PointLight.new(0xff6f91, 1.9, 8, 2)
  rim_light.position.set(-2.2, 1.6, 2.8)
  scene.add(rim_light)

  cool_light = Three::PointLight.new(0x8ed6ff, 1.1, 7, 2)
  cool_light.position.set(2.4, -0.8, 2.2)
  scene.add(cool_light)

  backdrop = Three::Mesh.new(
    Three::PlaneGeometry.new(7.2, 4.4, width_segments: 1, height_segments: 1),
    Three::MeshBasicMaterial.new(color: 0xf8fbff)
  )
  backdrop.position.z = -1.35
  scene.add(backdrop)

  ruby_material = Three::MeshPhysicalMaterial.new(
    color: 0xff2d64,
    roughness: 0.03,
    metalness: 0,
    opacity: 0.78,
    transparent: true,
    clearcoat: 1.0,
    clearcoat_roughness: 0.02,
    transmission: 0.96,
    thickness: 0.52,
    ior: 1.77,
    dispersion: 0.32,
    specular_intensity: 1.0,
    specular_color: 0xffeef3,
    attenuation_color: 0xff164b,
    attenuation_distance: 2.4,
    side: Three::DoubleSide,
    vertex_colors: false
  )
  ruby_gem = Three::Mesh.new(faceted_ruby_geometry, ruby_material)
  ruby_gem.position.set(0, 0.5, 0.1)
  ruby_gem.rotation.x = -0.16
  ruby_gem.rotation.y = 0.28
  ruby_gem.scale.set(1.08, 1.08, 1.08)
  ruby_gem.cast_shadow = true
  scene.add(ruby_gem)

  spark_materials = [
    Three::MeshBasicMaterial.new(color: 0xfff8cc, transparent: true, opacity: 0.9),
    Three::MeshBasicMaterial.new(color: 0xffffff, transparent: true, opacity: 0.84),
    Three::MeshBasicMaterial.new(color: 0xffd6e2, transparent: true, opacity: 0.78)
  ]
  sparkle_specs = [
    [[-0.84, 1.06, 0.72], 0.24, 0.05],
    [[0.98, 0.95, 0.78], 0.31, 1.15],
    [[1.24, 0.34, 0.72], 0.22, 2.3],
    [[-1.06, 0.18, 0.68], 0.2, 3.1],
    [[0.34, 1.24, 0.74], 0.18, 4.0]
  ]
  sparkles = sparkle_specs.each_with_index.map do |(position, size, phase), index|
    sparkle = build_spark(size, spark_materials[index % spark_materials.length])
    sparkle.position.set(*position)
    sparkle.rotation.z = phase
    scene.add(sparkle)
    [sparkle, phase]
  end

  title_font = Three::Loaders::FontLoader.new.load("/node_modules/three/examples/fonts/helvetiker_regular.typeface.json")
  title_geometry = Three::TextGeometry.new(
    "three-rb",
    font: title_font,
    size: 0.48,
    depth: 0.105,
    curve_segments: 10,
    bevel_enabled: true,
    bevel_thickness: 0.018,
    bevel_size: 0.01,
    bevel_segments: 3
  )
  title_material = Three::MeshPhysicalMaterial.new(
    color: 0x3c8fbd,
    roughness: 0.2,
    metalness: 0.08,
    clearcoat: 0.72,
    clearcoat_roughness: 0.16,
    specular_intensity: 0.9,
    specular_color: 0xe8fbff
  )
  title = Three::Mesh.new(title_geometry, title_material)
  title.position.set(0, -1.18, 0.08)
  title.rotation.x = -0.08
  title.cast_shadow = true
  scene.add(title)

  accent_material = Three::MeshStandardMaterial.new(color: 0xffb3c4, roughness: 0.36, metalness: 0.08)
  accent = Three::Mesh.new(Three::BoxGeometry.new(3.55, 0.035, 0.035), accent_material)
  accent.position.set(0, -1.45, 0.03)
  accent.rotation.z = -0.035
  scene.add(accent)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true,
    shadow_map_enabled: true,
    shadow_map_type: Three::PCFSoftShadowMap
  )
  renderer.set_clear_color(0xf8fbff, 1)
  renderer.handle[:toneMapping] = JS.global[:THREE][:ACESFilmicToneMapping]
  renderer.handle[:toneMappingExposure] = 1.18
  renderer.backend.materialize(title_geometry).call(:center)

  controls = Three::Controls::OrbitControls.new(
    camera,
    renderer: renderer,
    enable_damping: true,
    damping_factor: 0.07,
    auto_rotate: true,
    auto_rotate_speed: 0.72,
    enable_pan: false
  )
  controls.target.set(0, 0.34, 0.08)

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
  JS.global[:__threeRbControls] = controls.handle
  JS.global[:__threeRbScene] = renderer.backend.materialize(scene)
  JS.global[:__threeRbCamera] = renderer.backend.materialize(camera)
  JS.global[:__threeRbRubyGem] = renderer.backend.materialize(ruby_gem)
  JS.global[:__threeRbRubyGeometry] = renderer.backend.materialize(ruby_gem.geometry)
  JS.global[:__threeRbRubyMaterial] = renderer.backend.materialize(ruby_material)
  JS.global[:__threeRbRubyTitle] = renderer.backend.materialize(title)
  JS.global[:__threeRbRubyTitleGeometry] = renderer.backend.materialize(title_geometry)
  JS.global[:__threeRbRubyTitleMaterial] = renderer.backend.materialize(title_material)
  sparkle_handles = JS.global[:Array].new
  sparkles.each { |sparkle, _phase| sparkle_handles.call(:push, renderer.backend.materialize(sparkle)) }
  JS.global[:__threeRbRubySparkles] = sparkle_handles
  JS.global[:__threeRbRubyEnvironment] = renderer.backend.materialize(environment_texture)
  JS.global[:__threeRbRubyFontLoaded] = !!title_font.handle
  JS.global[:__threeRbRubyFrame] = 0

  frame = 0
  renderer.animation_loop do
    frame += 1
    ruby_gem.rotation.y += 0.009
    ruby_gem.rotation.z = Math.sin(frame * 0.012) * 0.045
    title.rotation.x = -0.08 + (Math.sin(frame * 0.015) * 0.018)
    title.rotation.y = Math.sin(frame * 0.018) * 0.055
    title.position.y = -1.18 + (Math.sin(frame * 0.02) * 0.025)
    title_twinkle = (Math.sin(frame * 0.048) + 1) / 2.0
    title_material.color.set_rgb(0.2 + (0.1 * title_twinkle), 0.48 + (0.12 * title_twinkle), 0.68 + (0.16 * title_twinkle))
    title_material.specular_intensity = 0.78 + (0.18 * title_twinkle)
    title_material.clearcoat = 0.62 + (0.18 * title_twinkle)
    accent.rotation.z = -0.035 + (Math.sin(frame * 0.018) * 0.008)
    accent.position.y = -1.45 + (Math.sin((frame * 0.014) + 1.2) * 0.005)
    accent.scale.x = 1.0 + (Math.sin(frame * 0.018) * 0.014)
    sparkles.each_with_index do |(sparkle, phase), index|
      pulse = (Math.sin((frame * 0.07) + phase) + 1) / 2.0
      scale = 0.58 + (pulse * 0.78)
      sparkle.scale.set(scale, scale, scale)
      sparkle.rotation.z += index.even? ? 0.018 : -0.014
    end

    JS.global[:__threeRbRubyFrame] = frame
    controls.update
    renderer.render(scene, camera)
  end

  status[:textContent] = "Running"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
