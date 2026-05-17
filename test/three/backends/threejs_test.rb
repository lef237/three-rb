# frozen_string_literal: true

require "test_helper"

class ThreeThreeJSBackendTest < Minitest::Test
  def test_materializes_scene_graph
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    scene = Three::Scene.new
    mesh = Three::Mesh.new(Three::BoxGeometry.new(1, 2, 3), Three::MeshBasicMaterial.new(color: 0x00ff00))
    scene.add(mesh)

    handle = backend.sync(scene)

    assert_equal :scene, handle[:type]
    assert_equal 1, handle[:children].length
    assert_equal :mesh, handle[:children].first[:type]
    assert_equal :box_geometry, handle[:children].first[:geometry][:type]
    assert_equal 0x00ff00, handle[:children].first[:material][:parameters][:color]
  end

  def test_syncs_instanced_mesh_matrices
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    mesh = Three::InstancedMesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new(color: 0x88ccff), 2)
    first_matrix = Three::Matrix4.new.make_translation(1, 0, 0)
    second_matrix = Three::Matrix4.new.make_translation(0, 2, 0)
    first_color = Three::Color.new(0xff0000)
    second_color = Three::Color.new(0x336699)

    mesh.set_matrix_at(0, first_matrix)
    mesh.set_matrix_at(1, second_matrix)
    mesh.set_color_at(0, first_color)
    mesh.set_color_at(1, second_color)

    handle = backend.sync(mesh)

    assert_equal :instanced_mesh, handle[:type]
    assert_equal 2, handle[:count]
    assert_equal first_matrix.to_a, handle[:instance_matrices][0]
    assert_equal second_matrix.to_a, handle[:instance_matrices][1]
    assert_equal true, handle[:instance_matrix_needs_update]
    assert_equal first_color.to_a, handle[:instance_colors][0]
    assert_equal second_color.to_a, handle[:instance_colors][1]
    assert_equal true, handle[:instance_color_needs_update]
    refute mesh.dirty?
  end

  def test_syncs_instanced_mesh_count_and_dirty_matrix_updates
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    mesh = Three::InstancedMesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new, 2)
    handle = backend.sync(mesh)

    adapter.calls.clear
    mesh.count = 1
    matrix = Three::Matrix4.new.make_translation(0, 0, 3)
    mesh.set_matrix_at(0, matrix)
    backend.sync(mesh)

    assert_same handle, backend.materialize(mesh)
    assert_equal 1, handle[:count]
    assert_equal 2, handle[:capacity]
    assert_equal matrix.to_a, handle[:instance_matrices][0]
    assert adapter.calls.any? { |call| call == [:set_instanced_mesh_count, handle, 1] }
    assert adapter.calls.any? { |call| call == [:set_instanced_mesh_matrix_at, handle, 0, matrix.to_a] }
    refute mesh.dirty?
  end

  def test_syncs_instanced_mesh_dirty_color_updates
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    mesh = Three::InstancedMesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new, 2)
    handle = backend.sync(mesh)

    adapter.calls.clear
    color = Three::Color.new(0x99cc33)
    mesh.set_color_at(1, color)
    backend.sync(mesh)

    assert_equal color.to_a, handle[:instance_colors][1]
    assert adapter.calls.any? { |call| call == [:set_instanced_mesh_color_at, handle, 1, color.to_a] }
    assert adapter.calls.any? { |call| call == [:set_instanced_mesh_instance_color_needs_update, handle, true] }
    refute adapter.calls.any? { |call| call[0] == :set_instanced_mesh_matrix_at }
    refute mesh.dirty?
  end

  def test_materializes_external_object3d_without_rebuilding_handle
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    scene = Three::Scene.new
    external_handle = { type: :gltf_scene, children: [{ type: :loaded_mesh }] }
    external = Three::ExternalObject3D.new(external_handle, type: "GLTFScene")

    scene.add(external)
    handle = backend.sync(scene)

    assert_same external_handle, handle[:children].first
    assert_equal [{ type: :loaded_mesh }], external_handle[:children]
  end

  def test_reuses_cached_handles
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    scene = Three::Scene.new

    first = backend.materialize(scene)
    second = backend.materialize(scene)

    assert_same first, second
  end

  def test_syncs_manual_object_matrix_when_auto_update_is_disabled
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    object = Three::Object3D.new
    object.matrix_auto_update = false
    object.matrix.make_translation(1, 2, 3)

    handle = backend.sync(object)

    assert_equal false, handle[:matrix_auto_update]
    assert_equal object.matrix.to_a, handle[:matrix]
    assert handle[:matrix_world_needs_update]
    refute adapter.calls.any? { |call| call[0] == :set_object_transform }
  end

  def test_materializes_generic_buffer_geometry
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    geometry = Three::BufferGeometry.new
    geometry.set_index([0, 1, 2])
    geometry.set_attribute(:position, Three::Float32BufferAttribute.new([0, 0, 0, 1, 0, 0, 0, 1, 0], 3))
    geometry.add_group(0, 3, 0)

    handle = backend.materialize(geometry)

    assert_equal :buffer_geometry, handle[:type]
    assert_equal :uint16, handle[:index][:component_type]
    assert_equal :float32, handle[:attributes][:position][:component_type]
    assert_equal [{ start: 0, count: 3, material_index: 0 }], handle[:groups]
  end

  def test_materializes_plane_geometry_with_threejs_builtin
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    geometry = Three::PlaneGeometry.new(2, 3, width_segments: 4, height_segments: 5)

    handle = backend.materialize(geometry)

    assert_equal :plane_geometry, handle[:type]
    assert_equal 2, handle[:width]
    assert_equal 3, handle[:height]
    assert_equal 4, handle[:width_segments]
    assert_equal 5, handle[:height_segments]
  end

  def test_materializes_sphere_geometry_with_threejs_builtin
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    geometry = Three::SphereGeometry.new(2, width_segments: 8, height_segments: 6, phi_start: 0.25, phi_length: 1.5, theta_start: 0.5, theta_length: 2.0)

    handle = backend.materialize(geometry)

    assert_equal :sphere_geometry, handle[:type]
    assert_equal 2, handle[:radius]
    assert_equal 8, handle[:width_segments]
    assert_equal 6, handle[:height_segments]
    assert_equal 0.25, handle[:phi_start]
    assert_equal 1.5, handle[:phi_length]
    assert_equal 0.5, handle[:theta_start]
    assert_equal 2.0, handle[:theta_length]
  end

  def test_materializes_text_geometry_with_threejs_addon
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    font = Three::Font.new({ type: :font, name: "Helvetiker" })
    geometry = Three::TextGeometry.new(
      "three-rb",
      font: font,
      size: 0.45,
      depth: 0.1,
      curve_segments: 8,
      bevel_enabled: true,
      bevel_thickness: 0.02,
      bevel_size: 0.01,
      bevel_segments: 3
    )

    handle = backend.materialize(geometry)

    assert_equal :text_geometry, handle[:type]
    assert_equal "three-rb", handle[:text]
    assert_same font.handle, handle[:parameters][:font]
    assert_equal 0.45, handle[:parameters][:size]
    assert_equal 0.1, handle[:parameters][:depth]
    assert_equal 8, handle[:parameters][:curveSegments]
    assert_equal true, handle[:parameters][:bevelEnabled]
    assert_equal 0.02, handle[:parameters][:bevelThickness]
    assert_equal 0.01, handle[:parameters][:bevelSize]
    assert_equal 3, handle[:parameters][:bevelSegments]
  end

  def test_materializes_mesh_normal_material
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    material = Three::MeshNormalMaterial.new(flat_shading: true, wireframe: true)

    handle = backend.materialize(material)

    assert_equal :mesh_normal_material, handle[:type]
    assert_equal true, handle[:parameters][:flatShading]
    assert_equal true, handle[:parameters][:wireframe]
  end

  def test_materializes_line_and_points_materials
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    line = Three::LineBasicMaterial.new(color: 0xff8844, linewidth: 2, linecap: "butt", linejoin: "miter", fog: false)
    points = Three::PointsMaterial.new(color: 0x66ddff, map: Three::Texture.new("/points.png"), size: 0.5, size_attenuation: false)
    sprite = Three::SpriteMaterial.new(color: 0xffcc4d, map: Three::Texture.new("/sprite.png"), rotation: 0.25, size_attenuation: false)

    line_handle = backend.materialize(line)
    points_handle = backend.materialize(points)
    sprite_handle = backend.materialize(sprite)

    assert_equal :line_basic_material, line_handle[:type]
    assert_equal 0xff8844, line_handle[:parameters][:color]
    assert_equal 2, line_handle[:parameters][:linewidth]
    assert_equal "butt", line_handle[:parameters][:linecap]
    assert_equal "miter", line_handle[:parameters][:linejoin]
    assert_equal false, line_handle[:parameters][:fog]
    assert_equal :points_material, points_handle[:type]
    assert_equal 0x66ddff, points_handle[:parameters][:color]
    assert_equal "/points.png", points_handle[:parameters][:map][:source]
    assert_equal 0.5, points_handle[:parameters][:size]
    assert_equal false, points_handle[:parameters][:sizeAttenuation]
    assert_equal :sprite_material, sprite_handle[:type]
    assert_equal 0xffcc4d, sprite_handle[:parameters][:color]
    assert_equal "/sprite.png", sprite_handle[:parameters][:map][:source]
    assert_equal 0.25, sprite_handle[:parameters][:rotation]
    assert_equal false, sprite_handle[:parameters][:sizeAttenuation]
    assert_equal true, sprite_handle[:parameters][:transparent]
  end

  def test_materializes_shadow_material
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    material = Three::ShadowMaterial.new(color: 0x112233, opacity: 0.32, fog: false)

    handle = backend.materialize(material)

    assert_equal :shadow_material, handle[:type]
    assert_equal 0x112233, handle[:parameters][:color]
    assert_equal 0.32, handle[:parameters][:opacity]
    assert_equal true, handle[:parameters][:transparent]
    assert_equal false, handle[:parameters][:fog]
  end

  def test_materializes_material_vertex_colors
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    material = Three::MeshBasicMaterial.new(vertex_colors: true)

    handle = backend.materialize(material)

    assert_equal true, handle[:parameters][:vertexColors]
  end

  def test_materializes_mesh_lambert_material
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    material = Three::MeshLambertMaterial.new(color: 0x224466, map: Three::Texture.new("/texture.png"), flat_shading: true)

    handle = backend.materialize(material)

    assert_equal :mesh_lambert_material, handle[:type]
    assert_equal 0x224466, handle[:parameters][:color]
    assert_equal :texture, handle[:parameters][:map][:type]
    assert_equal "/texture.png", handle[:parameters][:map][:source]
    assert_equal true, handle[:parameters][:flatShading]
  end

  def test_materializes_mesh_matcap_material
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    matcap = Three::Texture.new("/matcap.png")
    material = Three::MeshMatcapMaterial.new(
      color: 0x99ccff,
      matcap: matcap,
      map: Three::Texture.new("/texture.png"),
      flat_shading: true
    )

    handle = backend.materialize(material)

    assert_equal :mesh_matcap_material, handle[:type]
    assert_equal 0x99ccff, handle[:parameters][:color]
    assert_equal "/matcap.png", handle[:parameters][:matcap][:source]
    assert_equal "/texture.png", handle[:parameters][:map][:source]
    assert_equal true, handle[:parameters][:flatShading]
  end

  def test_materializes_mesh_toon_material
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    gradient_map = Three::Texture.new("/gradient.png")
    material = Three::MeshToonMaterial.new(
      color: 0x99ccff,
      emissive: 0x111827,
      map: Three::Texture.new("/texture.png"),
      gradient_map: gradient_map,
      flat_shading: true
    )

    handle = backend.materialize(material)

    assert_equal :mesh_toon_material, handle[:type]
    assert_equal 0x99ccff, handle[:parameters][:color]
    assert_equal 0x111827, handle[:parameters][:emissive]
    assert_equal "/texture.png", handle[:parameters][:map][:source]
    assert_equal "/gradient.png", handle[:parameters][:gradientMap][:source]
    assert_equal true, handle[:parameters][:flatShading]
  end

  def test_materializes_mesh_phong_material
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    specular_map = Three::Texture.new("/specular.png")
    material = Three::MeshPhongMaterial.new(
      color: 0x224466,
      specular: 0xe8f1ff,
      emissive: 0x111827,
      shininess: 64,
      map: Three::Texture.new("/texture.png"),
      specular_map: specular_map,
      flat_shading: true
    )

    handle = backend.materialize(material)

    assert_equal :mesh_phong_material, handle[:type]
    assert_equal 0x224466, handle[:parameters][:color]
    assert_equal 0xe8f1ff, handle[:parameters][:specular]
    assert_equal 0x111827, handle[:parameters][:emissive]
    assert_equal 64, handle[:parameters][:shininess]
    assert_equal "/texture.png", handle[:parameters][:map][:source]
    assert_equal "/specular.png", handle[:parameters][:specularMap][:source]
    assert_equal true, handle[:parameters][:flatShading]
  end

  def test_materializes_mesh_standard_material
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    normal_map = Three::Texture.new("/normal.png")
    roughness_map = Three::Texture.new("/roughness.png")
    metalness_map = Three::Texture.new("/metalness.png")
    material = Three::MeshStandardMaterial.new(
      color: 0x336699,
      roughness: 0.4,
      metalness: 0.7,
      map: Three::Texture.new("/texture.png"),
      normal_map: normal_map,
      roughness_map: roughness_map,
      metalness_map: metalness_map,
      flat_shading: true
    )

    handle = backend.materialize(material)

    assert_equal :mesh_standard_material, handle[:type]
    assert_equal 0x336699, handle[:parameters][:color]
    assert_equal 0.4, handle[:parameters][:roughness]
    assert_equal 0.7, handle[:parameters][:metalness]
    assert_equal :texture, handle[:parameters][:map][:type]
    assert_equal "/texture.png", handle[:parameters][:map][:source]
    assert_equal "/normal.png", handle[:parameters][:normalMap][:source]
    assert_equal "/roughness.png", handle[:parameters][:roughnessMap][:source]
    assert_equal "/metalness.png", handle[:parameters][:metalnessMap][:source]
    assert_equal true, handle[:parameters][:flatShading]
  end

  def test_materializes_mesh_physical_material
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    anisotropy_map = Three::Texture.new("/anisotropy.png")
    clearcoat_map = Three::Texture.new("/clearcoat.png")
    transmission_map = Three::Texture.new("/transmission.png")
    material = Three::MeshPhysicalMaterial.new(
      color: 0x99ccff,
      roughness: 0.35,
      metalness: 0.1,
      anisotropy: 0.4,
      anisotropy_rotation: 0.2,
      anisotropy_map: anisotropy_map,
      clearcoat: 0.8,
      clearcoat_roughness: 0.25,
      clearcoat_map: clearcoat_map,
      transmission: 0.45,
      transmission_map: transmission_map,
      thickness: 0.2,
      ior: 1.45,
      reflectivity: 0.35,
      iridescence: 0.2,
      iridescence_ior: 1.15,
      iridescence_thickness_range: [120, 360],
      sheen: 0.3,
      sheen_color: 0x223344,
      sheen_roughness: 0.65,
      dispersion: 0.1,
      specular_intensity: 0.7,
      specular_color: 0xf0f6ff,
      attenuation_distance: 5,
      attenuation_color: 0x88aaff
    )

    handle = backend.materialize(material)

    assert_equal :mesh_physical_material, handle[:type]
    assert_equal 0x99ccff, handle[:parameters][:color]
    assert_equal 0.35, handle[:parameters][:roughness]
    assert_equal 0.1, handle[:parameters][:metalness]
    assert_equal 0.4, handle[:parameters][:anisotropy]
    assert_equal 0.2, handle[:parameters][:anisotropyRotation]
    assert_equal "/anisotropy.png", handle[:parameters][:anisotropyMap][:source]
    assert_equal 0.8, handle[:parameters][:clearcoat]
    assert_equal 0.25, handle[:parameters][:clearcoatRoughness]
    assert_equal "/clearcoat.png", handle[:parameters][:clearcoatMap][:source]
    assert_equal 0.45, handle[:parameters][:transmission]
    assert_equal "/transmission.png", handle[:parameters][:transmissionMap][:source]
    assert_equal 0.2, handle[:parameters][:thickness]
    assert_in_delta 1.3255813953488373, handle[:parameters][:ior]
    assert_equal 0.35, handle[:parameters][:reflectivity]
    assert_equal 0.2, handle[:parameters][:iridescence]
    assert_equal 1.15, handle[:parameters][:iridescenceIOR]
    assert_equal [120, 360], handle[:parameters][:iridescenceThicknessRange]
    assert_equal 0.3, handle[:parameters][:sheen]
    assert_equal 0x223344, handle[:parameters][:sheenColor]
    assert_equal 0.65, handle[:parameters][:sheenRoughness]
    assert_equal 0.1, handle[:parameters][:dispersion]
    assert_equal 0.7, handle[:parameters][:specularIntensity]
    assert_equal 0xf0f6ff, handle[:parameters][:specularColor]
    assert_equal 5, handle[:parameters][:attenuationDistance]
    assert_equal 0x88aaff, handle[:parameters][:attenuationColor]
  end

  def test_materializes_texture
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    texture = Three::Texture.new(
      "/texture.png",
      flip_y: false,
      wrap_s: Three::RepeatWrapping,
      wrap_t: Three::MirroredRepeatWrapping,
      mag_filter: Three::NearestFilter,
      min_filter: Three::NearestMipmapNearestFilter,
      offset: [0.25, 0.5],
      repeat: [2, 3]
    )

    handle = backend.materialize(texture)

    assert_equal :texture, handle[:type]
    assert_equal "/texture.png", handle[:source]
    assert_equal Three::UVMapping, handle[:mapping]
    assert_equal Three::NoColorSpace, handle[:color_space]
    assert_equal false, handle[:flip_y]
    assert_equal Three::RepeatWrapping, handle[:wrap_s]
    assert_equal Three::MirroredRepeatWrapping, handle[:wrap_t]
    assert_equal Three::NearestFilter, handle[:mag_filter]
    assert_equal Three::NearestMipmapNearestFilter, handle[:min_filter]
    assert_equal [0.25, 0.5], handle[:offset]
    assert_equal [2, 3], handle[:repeat]
    assert_equal [0, 0], handle[:center]
    assert_equal 0, handle[:rotation]
    assert_equal true, handle[:matrix_auto_update]
    assert_equal Three::Matrix3.new.elements, handle[:matrix]
    refute texture.dirty?
  end

  def test_materializes_cube_texture
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    sources = %w[/px.png /nx.png /py.png /ny.png /pz.png /nz.png]
    texture = Three::CubeTexture.new(
      sources,
      flip_y: false,
      wrap_s: Three::ClampToEdgeWrapping,
      wrap_t: Three::ClampToEdgeWrapping,
      mag_filter: Three::LinearFilter,
      min_filter: Three::LinearMipmapLinearFilter
    )

    handle = backend.materialize(texture)

    assert_equal :cube_texture, handle[:type]
    assert_equal sources, handle[:sources]
    assert_equal Three::CubeReflectionMapping, handle[:mapping]
    assert_equal Three::NoColorSpace, handle[:color_space]
    assert_equal false, handle[:flip_y]
    assert_equal Three::ClampToEdgeWrapping, handle[:wrap_s]
    assert_equal Three::ClampToEdgeWrapping, handle[:wrap_t]
    assert_equal Three::LinearFilter, handle[:mag_filter]
    assert_equal Three::LinearMipmapLinearFilter, handle[:min_filter]
    refute texture.dirty?
  end

  def test_materializes_rgbe_texture
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    texture = Three::RGBETexture.new("/studio.hdr")

    handle = backend.materialize(texture)

    assert_equal :rgbe_texture, handle[:type]
    assert_equal "/studio.hdr", handle[:source]
    assert_equal Three::EquirectangularReflectionMapping, handle[:mapping]
    assert_equal Three::LinearSRGBColorSpace, handle[:color_space]
    assert_equal true, handle[:flip_y]
    assert_equal Three::LinearFilter, handle[:mag_filter]
    assert_equal Three::LinearFilter, handle[:min_filter]
    refute texture.dirty?
  end

  def test_sync_updates_dirty_texture_only_after_change
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    texture = Three::Texture.new("/texture.png", repeat: [1, 1])

    handle = backend.sync(texture)
    adapter.calls.clear
    backend.sync(texture)

    assert_empty adapter.calls

    texture.repeat.set(4, 5)
    texture.offset.set(0.25, 0.5)
    backend.sync(texture)

    assert_equal :update_texture, adapter.calls.last[0]
    assert_same handle, adapter.calls.last[1]
    assert_equal [0.25, 0.5], adapter.calls.last[2][:offset]
    assert_equal [4, 5], adapter.calls.last[2][:repeat]
    refute texture.dirty?
  end

  def test_sync_scene_background_and_environment
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    scene = Three::Scene.new
    background = Three::CubeTexture.new(%w[/px.png /nx.png /py.png /ny.png /pz.png /nz.png])
    environment = Three::CubeTexture.new(%w[/epx.png /enx.png /epy.png /eny.png /epz.png /enz.png])

    scene.background = background
    scene.environment = environment
    handle = backend.sync(scene)

    assert_equal :scene, handle[:type]
    assert_equal :cube_texture, handle[:background][:type]
    assert_equal :cube_texture, handle[:environment][:type]
    assert adapter.calls.any? { |call| call == [:set_scene_background, handle, handle[:background]] }
    assert adapter.calls.any? { |call| call == [:set_scene_environment, handle, handle[:environment]] }
    refute scene.dirty?
  end

  def test_sync_updates_dirty_scene_background_texture
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    scene = Three::Scene.new
    texture = Three::CubeTexture.new(%w[/px.png /nx.png /py.png /ny.png /pz.png /nz.png])

    scene.background = texture
    handle = backend.sync(scene)
    adapter.calls.clear

    texture.wrap_s = Three::RepeatWrapping
    backend.sync(scene)

    assert_equal :update_texture, adapter.calls[0][0]
    assert_same handle[:background], adapter.calls[0][1]
    assert_equal Three::RepeatWrapping, adapter.calls[0][2][:wrap_s]
    assert adapter.calls.any? { |call| call == [:set_scene_background, handle, handle[:background]] }
    refute texture.dirty?
  end

  def test_materializes_orthographic_camera
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    camera = Three::OrthographicCamera.new(-2, 2, 1, -1, near: 0.5, far: 50)

    handle = backend.materialize(camera)

    assert_equal :orthographic_camera, handle[:type]
    assert_equal(-2, handle[:left])
    assert_equal 2, handle[:right]
    assert_equal 1, handle[:top]
    assert_equal(-1, handle[:bottom])
    assert_equal 0.5, handle[:near]
    assert_equal 50, handle[:far]
  end

  def test_materializes_lights
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)

    ambient = backend.materialize(Three::AmbientLight.new(0x112233, 0.5))
    directional = backend.materialize(Three::DirectionalLight.new(0xffffff, 1.25))
    point = backend.materialize(Three::PointLight.new(0xffddaa, 1.5, 10, 2))
    hemisphere = backend.materialize(Three::HemisphereLight.new(0xddeeff, 0x223344, 0.75))

    assert_equal :ambient_light, ambient[:type]
    assert_equal 0x112233, ambient[:color]
    assert_equal 0.5, ambient[:intensity]
    assert_equal :directional_light, directional[:type]
    assert_equal 0xffffff, directional[:color]
    assert_equal 1.25, directional[:intensity]
    assert_equal :point_light, point[:type]
    assert_equal 0xffddaa, point[:color]
    assert_equal 1.5, point[:intensity]
    assert_equal 10, point[:distance]
    assert_equal 2, point[:decay]
    assert_equal :hemisphere_light, hemisphere[:type]
    assert_equal 0xddeeff, hemisphere[:sky_color]
    assert_equal 0x223344, hemisphere[:ground_color]
    assert_equal 0.75, hemisphere[:intensity]
  end

  def test_materializes_line_and_points_objects
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    geometry = Three::BufferGeometry.new
    geometry.set_attribute(:position, Three::Float32BufferAttribute.new([0, 0, 0, 1, 0, 0], 3))
    line = Three::Line.new(geometry, Three::LineBasicMaterial.new(color: 0xff0000))
    points = Three::Points.new(geometry, Three::PointsMaterial.new(color: 0x00ff00, size: 2))

    line_handle = backend.sync(line)
    points_handle = backend.sync(points)

    assert_equal :line, line_handle[:type]
    assert_equal :buffer_geometry, line_handle[:geometry][:type]
    assert_equal :line_basic_material, line_handle[:material][:type]
    assert_equal 0xff0000, line_handle[:material][:parameters][:color]
    assert_equal :points, points_handle[:type]
    assert_same line_handle[:geometry], points_handle[:geometry]
    assert_equal :points_material, points_handle[:material][:type]
    assert_equal 2, points_handle[:material][:parameters][:size]
  end

  def test_materializes_sprite_object
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    sprite = Three::Sprite.new(Three::SpriteMaterial.new(color: 0xffcc4d))
    sprite.center = [0.25, 0.75]
    sprite.scale.set(0.4, 0.4, 1)

    handle = backend.sync(sprite)

    assert_equal :sprite, handle[:type]
    assert_equal :sprite_material, handle[:material][:type]
    assert_equal 0xffcc4d, handle[:material][:parameters][:color]
    assert_equal [0.25, 0.75], handle[:center]
    assert_equal [0.4, 0.4, 1], handle[:scale]
  end

  def test_sync_updates_object_transform
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    object = Three::Object3D.new
    object.name = "node"
    object.cast_shadow = true
    object.receive_shadow = true
    object.position.set(1, 2, 3)
    object.scale.set(2, 2, 2)

    handle = backend.sync(object)

    assert_equal "node", handle[:name]
    assert_equal true, handle[:cast_shadow]
    assert_equal true, handle[:receive_shadow]
    assert_equal 1, handle[:layers]
    assert_equal [1, 2, 3], handle[:position]
    assert_equal [2, 2, 2], handle[:scale]
  end

  def test_sync_updates_object_layers_only_after_change
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    object = Three::Object3D.new

    handle = backend.sync(object)
    adapter.calls.clear
    backend.sync(object)

    assert_empty adapter.calls

    object.layers.set(4)
    backend.sync(object)

    assert_equal [:set_object_layers, handle, 1 << 4], adapter.calls.last
  end

  def test_sync_updates_directional_light_shadow
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    light = Three::DirectionalLight.new
    light.cast_shadow = true
    light.shadow_map_size = [1024, 1024]
    light.shadow_bias = -0.0001
    light.shadow_normal_bias = 0.01
    light.shadow_radius = 2
    light.set_shadow_camera(left: -3, right: 3, top: 2, bottom: -2, near: 0.2, far: 20)

    handle = backend.sync(light)

    assert_equal true, handle[:cast_shadow]
    shadow_call = adapter.calls.find { |call| call[0] == :update_light_shadow }
    refute_nil shadow_call
    assert_equal({
      map_size: [1024, 1024],
      bias: -0.0001,
      normal_bias: 0.01,
      radius: 2,
      camera: { left: -3, right: 3, top: 2, bottom: -2, near: 0.2, far: 20 }
    }, shadow_call[2])
  end

  def test_render_materializes_and_delegates
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = backend.create_renderer(canvas: "#canvas")
    scene = Three::Scene.new
    camera = Three::PerspectiveCamera.new

    backend.render(renderer, scene, camera)

    assert_equal :render, adapter.calls.last[0]
    assert_same renderer, adapter.calls.last[1]
    assert_equal :scene, adapter.calls.last[2][:type]
    assert_equal :perspective_camera, adapter.calls.last[3][:type]
  end

  def test_dispose_removes_cached_handle
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    geometry = Three::BufferGeometry.new
    handle = backend.materialize(geometry)

    disposed = backend.dispose(geometry)

    assert_same handle, disposed
    assert_equal [:dispose, handle], adapter.calls.last
    refute_includes backend.handles.values, handle
  end

  def test_dispose_material_and_texture_remove_cached_handles
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    texture = Three::Texture.new("/texture.png")
    material = Three::MeshBasicMaterial.new(map: texture)

    material_handle = backend.materialize(material)
    texture_handle = backend.materialize(texture)
    adapter.calls.clear

    disposed_material = backend.dispose(material)
    disposed_texture = backend.dispose(texture)

    assert_same material_handle, disposed_material
    assert_same texture_handle, disposed_texture
    assert_equal [
      [:dispose, material_handle],
      [:dispose, texture_handle]
    ], adapter.calls
    refute backend.handles.key?(material.uuid)
    refute backend.handles.key?(texture.uuid)
  end

  def test_dispose_material_can_dispose_texture_maps
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    texture = Three::Texture.new("/texture.png")
    normal_map = Three::Texture.new("/normal.png")
    matcap = Three::Texture.new("/matcap.png")
    material = Three::MeshMatcapMaterial.new(matcap: matcap, map: texture, normal_map: normal_map)

    material_handle = backend.materialize(material)
    texture_handle = backend.materialize(texture)
    normal_map_handle = backend.materialize(normal_map)
    matcap_handle = backend.materialize(matcap)
    adapter.calls.clear

    disposed_material = backend.dispose(material, dispose_textures: true)

    assert_same material_handle, disposed_material
    assert_equal [
      [:dispose, matcap_handle],
      [:dispose, texture_handle],
      [:dispose, normal_map_handle],
      [:dispose, material_handle]
    ], adapter.calls
    refute backend.handles.key?(material.uuid)
    refute backend.handles.key?(texture.uuid)
    refute backend.handles.key?(normal_map.uuid)
    refute backend.handles.key?(matcap.uuid)
  end

  def test_dispose_toon_material_can_dispose_gradient_map
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    texture = Three::Texture.new("/texture.png")
    gradient_map = Three::Texture.new("/gradient.png")
    material = Three::MeshToonMaterial.new(map: texture, gradient_map: gradient_map)

    material_handle = backend.materialize(material)
    texture_handle = backend.materialize(texture)
    gradient_map_handle = backend.materialize(gradient_map)
    adapter.calls.clear

    disposed_material = backend.dispose(material, dispose_textures: true)

    assert_same material_handle, disposed_material
    assert_equal [
      [:dispose, texture_handle],
      [:dispose, gradient_map_handle],
      [:dispose, material_handle]
    ], adapter.calls
    refute backend.handles.key?(material.uuid)
    refute backend.handles.key?(texture.uuid)
    refute backend.handles.key?(gradient_map.uuid)
  end

  def test_dispose_subtree_disposes_sprite_material_and_texture
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    texture = Three::Texture.new("/sprite.png")
    material = Three::SpriteMaterial.new(map: texture)
    sprite = Three::Sprite.new(material)

    sprite_handle = backend.sync(sprite)
    material_handle = backend.materialize(material)
    texture_handle = backend.materialize(texture)
    adapter.calls.clear

    disposed = backend.dispose_subtree(sprite, dispose_textures: true)

    assert_same sprite_handle, disposed
    assert_equal [
      [:dispose, material_handle],
      [:dispose, texture_handle]
    ], adapter.calls
    refute backend.handles.key?(sprite.uuid)
    refute backend.handles.key?(material.uuid)
    refute backend.handles.key?(texture.uuid)
  end

  def test_traverse_handles_walks_external_object3d_handle
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    child = { type: :loaded_mesh, children: [{ type: :loaded_child, children: [] }] }
    external = Three::ExternalObject3D.new({ type: :gltf_scene, children: [child] }, type: "GLTFScene")
    visited = []

    handle = backend.traverse_handles(external) { |node| visited << node[:type] }

    assert_same external.handle, handle
    assert_equal %i[gltf_scene loaded_mesh loaded_child], visited
  end

  def test_dispose_subtree_disposes_external_resources_and_removes_root
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    geometry = { type: :loaded_geometry }
    texture = { type: :loaded_texture }
    material = { type: :loaded_material, map: texture }
    skeleton = { type: :loaded_skeleton }
    mesh = { type: :loaded_mesh, geometry: geometry, material: material, skeleton: skeleton, children: [] }
    external = Three::ExternalObject3D.new({ type: :gltf_scene, children: [mesh] }, type: "GLTFScene")
    scene = Three::Scene.new
    scene.add(external)
    scene_handle = backend.sync(scene)
    adapter.calls.clear

    disposed = backend.dispose_subtree(external, dispose_textures: true)

    assert_same external.handle, disposed
    refute_includes scene.children, external
    assert_nil external.parent
    refute_includes scene_handle[:children], external.handle
    refute backend.handles.key?(external.uuid)
    assert_equal [
      [:dispose, geometry],
      [:dispose, material],
      [:dispose, texture],
      [:dispose, skeleton]
    ], adapter.calls
  end

  def test_dispose_subtree_keeps_textures_by_default_at_backend_layer
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    geometry = { type: :loaded_geometry }
    texture = { type: :loaded_texture }
    material = { type: :loaded_material, map: texture }
    mesh = { type: :loaded_mesh, geometry: geometry, material: material, children: [] }
    external = Three::ExternalObject3D.new({ type: :gltf_scene, children: [mesh] }, type: "GLTFScene")

    backend.dispose_subtree(external)

    assert_equal [
      [:dispose, geometry],
      [:dispose, material]
    ], adapter.calls
  end

  def test_sync_skips_clean_object_updates
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    object = Three::Object3D.new

    backend.sync(object)
    adapter.calls.clear
    backend.sync(object)

    assert_empty adapter.calls

    object.position.set(1, 2, 3)
    backend.sync(object)

    assert_equal :set_object_transform, adapter.calls.last[0]
  end

  def test_sync_skips_clean_child_subtrees
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    scene = Three::Scene.new
    clean_mesh = Three::Mesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new)
    dirty_mesh = Three::Mesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new)
    scene.add(clean_mesh, dirty_mesh)

    backend.sync(scene)
    clean_handle = backend.materialize(clean_mesh)
    dirty_handle = backend.materialize(dirty_mesh)
    adapter.calls.clear

    dirty_mesh.position.x = 1
    backend.sync(scene)

    transform_calls = adapter.calls.select { |call| call[0] == :set_object_transform }
    assert_equal 1, transform_calls.length
    assert_same dirty_handle, transform_calls.first[1]
    refute transform_calls.any? { |call| call[1].equal?(clean_handle) }
  end

  def test_sync_reaches_dirty_material_through_clean_scene_graph
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    scene = Three::Scene.new
    material = Three::MeshBasicMaterial.new(color: 0xff0000)
    mesh = Three::Mesh.new(Three::BoxGeometry.new, material)
    scene.add(mesh)

    backend.sync(scene)
    material_handle = backend.materialize(material)
    adapter.calls.clear

    material.color.set_hex(0x00ff00)
    backend.sync(scene)

    call = adapter.calls.find { |entry| entry[0] == :update_material && entry[1].equal?(material_handle) }
    refute_nil call
    assert_equal 0x00ff00, call[2][:color]
  end

  def test_sync_reaches_dirty_texture_through_clean_scene_graph
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    scene = Three::Scene.new
    texture = Three::Texture.new("/texture.png", repeat: [1, 1])
    material = Three::MeshBasicMaterial.new(map: texture)
    mesh = Three::Mesh.new(Three::BoxGeometry.new, material)
    scene.add(mesh)

    backend.sync(scene)
    texture_handle = backend.materialize(texture)
    adapter.calls.clear

    texture.repeat.set(2, 3)
    backend.sync(scene)

    call = adapter.calls.find { |entry| entry[0] == :update_texture && entry[1].equal?(texture_handle) }
    refute_nil call
    assert_equal [2, 3], call[2][:repeat]
  end

  def test_sync_reaches_dirty_geometry_through_clean_scene_graph
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    scene = Three::Scene.new
    geometry = Three::BufferGeometry.new
    geometry.set_attribute(:position, Three::Float32BufferAttribute.new([0, 0, 0, 1, 0, 0, 0, 1, 0], 3))
    material = Three::MeshBasicMaterial.new
    mesh = Three::Mesh.new(geometry, material)
    scene.add(mesh)

    backend.sync(scene)
    geometry_handle = backend.materialize(geometry)
    adapter.calls.clear

    geometry.set_draw_range(0, 3)
    backend.sync(scene)

    assert adapter.calls.any? { |call| call == [:set_geometry_draw_range, geometry_handle, 0, 3] }
  end

  def test_sync_updates_dirty_line_material_reference
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    line = Three::Line.new(Three::BufferGeometry.new, Three::LineBasicMaterial.new(color: 0xff0000))
    handle = backend.sync(line)
    adapter.calls.clear

    material = Three::LineBasicMaterial.new(color: 0x00ff00)
    line.material = material
    backend.sync(line)

    material_handle = backend.materialize(material)
    assert adapter.calls.any? { |call| call == [:set_object_material, handle, material_handle] }
  end

  def test_sync_updates_dirty_material_only
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    material = Three::MeshBasicMaterial.new(color: 0xff0000)

    backend.sync(material)
    adapter.calls.clear
    backend.sync(material)

    assert_empty adapter.calls

    material.color.set_hex(0x00ff00)
    backend.sync(material)

    assert_equal :update_material, adapter.calls.last[0]
    assert_equal 0x00ff00, adapter.calls.last[2][:color]
  end

  def test_sync_updates_dirty_mesh_standard_material_parameters
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    material = Three::MeshStandardMaterial.new(roughness: 1, metalness: 0)

    backend.sync(material)
    adapter.calls.clear

    material.roughness = 0.25
    material.metalness = 0.85
    backend.sync(material)

    assert_equal :update_material, adapter.calls.last[0]
    assert_equal 0.25, adapter.calls.last[2][:roughness]
    assert_equal 0.85, adapter.calls.last[2][:metalness]
  end

  def test_sync_updates_dirty_mesh_matcap_material_parameters
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    material = Three::MeshMatcapMaterial.new(color: 0xffffff)

    backend.sync(material)
    adapter.calls.clear

    material.color.set_hex(0x99ccff)
    material.flat_shading = true
    backend.sync(material)

    assert_equal :update_material, adapter.calls.last[0]
    assert_equal 0x99ccff, adapter.calls.last[2][:color]
    assert_equal true, adapter.calls.last[2][:flatShading]
  end

  def test_sync_updates_dirty_mesh_toon_material_parameters
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    material = Three::MeshToonMaterial.new(color: 0xffffff, emissive: 0x000000)

    backend.sync(material)
    adapter.calls.clear

    material.color.set_hex(0x99ccff)
    material.emissive.set_hex(0x101820)
    material.flat_shading = true
    backend.sync(material)

    assert_equal :update_material, adapter.calls.last[0]
    assert_equal 0x99ccff, adapter.calls.last[2][:color]
    assert_equal 0x101820, adapter.calls.last[2][:emissive]
    assert_equal true, adapter.calls.last[2][:flatShading]
  end

  def test_sync_updates_dirty_sprite_material_and_center
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    material = Three::SpriteMaterial.new(color: 0xffffff, rotation: 0)
    sprite = Three::Sprite.new(material)

    handle = backend.sync(sprite)
    adapter.calls.clear

    material.color.set_hex(0xffcc4d)
    material.rotation = 0.5
    sprite.center.set(0.25, 0.75)
    backend.sync(sprite)

    assert_includes adapter.calls, [:set_sprite_center, handle, [0.25, 0.75]]
    update_call = adapter.calls.find { |call| call[0] == :update_material }
    refute_nil update_call
    assert_equal 0xffcc4d, update_call[2][:color]
    assert_equal 0.5, update_call[2][:rotation]
  end

  def test_sync_updates_dirty_mesh_physical_material_parameters
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    material = Three::MeshPhysicalMaterial.new(clearcoat: 0.1, specular_color: 0xffffff)

    backend.sync(material)
    adapter.calls.clear

    material.clearcoat = 0.6
    material.specular_color.set_hex(0x88aaff)
    backend.sync(material)

    assert_equal :update_material, adapter.calls.last[0]
    assert_equal 0.6, adapter.calls.last[2][:clearcoat]
    assert_equal 0x88aaff, adapter.calls.last[2][:specularColor]
  end

  def test_sync_updates_dirty_mesh_phong_material_parameters
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    material = Three::MeshPhongMaterial.new(specular: 0x111111, emissive: 0x000000, shininess: 30)

    backend.sync(material)
    adapter.calls.clear

    material.specular.set_hex(0xf0f6ff)
    material.emissive.set_hex(0x101820)
    material.shininess = 92
    backend.sync(material)

    assert_equal :update_material, adapter.calls.last[0]
    assert_equal 0xf0f6ff, adapter.calls.last[2][:specular]
    assert_equal 0x101820, adapter.calls.last[2][:emissive]
    assert_equal 92, adapter.calls.last[2][:shininess]
  end

  def test_sync_updates_dirty_shadow_material_parameters
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    material = Three::ShadowMaterial.new(color: 0x000000, opacity: 0.25)

    backend.sync(material)
    adapter.calls.clear

    material.color.set_hex(0x112233)
    material.opacity = 0.45
    material.fog = false
    backend.sync(material)

    assert_equal :update_material, adapter.calls.last[0]
    assert_equal 0x112233, adapter.calls.last[2][:color]
    assert_equal 0.45, adapter.calls.last[2][:opacity]
    assert_equal false, adapter.calls.last[2][:fog]
  end

  def test_sync_updates_dirty_material_texture_even_when_material_is_clean
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    texture = Three::Texture.new("/texture.png")
    roughness_map = Three::Texture.new("/roughness.png")
    material = Three::MeshStandardMaterial.new(map: texture, roughness_map: roughness_map)

    backend.materialize(texture)
    roughness_map_handle = backend.materialize(roughness_map)
    backend.sync(material)
    adapter.calls.clear

    roughness_map.repeat.set(2, 2)
    backend.sync(material)

    assert_includes adapter.calls, [:update_texture, roughness_map_handle, {
      mapping: Three::UVMapping,
      color_space: Three::NoColorSpace,
      flip_y: true,
      wrap_s: Three::ClampToEdgeWrapping,
      wrap_t: Three::ClampToEdgeWrapping,
      mag_filter: Three::LinearFilter,
      min_filter: Three::LinearMipmapLinearFilter,
      offset: [0, 0],
      repeat: [2, 2],
      center: [0, 0],
      rotation: 0,
      matrix_auto_update: true,
      matrix: Three::Matrix3.new.elements
    }]
  end

  def test_sync_updates_dirty_orthographic_camera_only_after_change
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    camera = Three::OrthographicCamera.new(-2, 2, 1, -1, near: 0.5, far: 50)

    handle = backend.sync(camera)
    adapter.calls.clear
    backend.sync(camera)

    assert_empty adapter.calls

    camera.zoom = 2
    backend.sync(camera)

    assert_equal [:update_orthographic_camera, handle, -2, 2, 1, -1, 0.5, 50, 2], adapter.calls.last
  end

  def test_sync_updates_dirty_light_only_after_change
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    light = Three::DirectionalLight.new(0xffffff, 1)

    handle = backend.sync(light)
    adapter.calls.clear
    backend.sync(light)

    assert_empty adapter.calls

    light.color.set_hex(0x224466)
    light.intensity = 0.75
    backend.sync(light)

    assert_equal [:update_light, handle, 0x224466, 0.75], adapter.calls.last
  end

  def test_sync_updates_dirty_point_light_only_after_change
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    light = Three::PointLight.new(0xffffff, 1, 0, 2)

    handle = backend.sync(light)
    adapter.calls.clear
    backend.sync(light)

    assert_empty adapter.calls

    light.color.set_hex(0x336699)
    light.intensity = 0.8
    light.distance = 12
    light.decay = 1.6
    backend.sync(light)

    assert_equal [:update_point_light, handle, 0x336699, 0.8, 12, 1.6], adapter.calls.last
  end

  def test_sync_updates_dirty_hemisphere_light_only_after_change
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    light = Three::HemisphereLight.new(0xffffff, 0x111111, 1)

    handle = backend.sync(light)
    adapter.calls.clear
    backend.sync(light)

    assert_empty adapter.calls

    light.color.set_hex(0xddeeff)
    light.ground_color.set_hex(0x223344)
    light.intensity = 0.4
    backend.sync(light)

    assert_equal [:update_hemisphere_light, handle, 0xddeeff, 0x223344, 0.4], adapter.calls.last
  end

  def test_sync_updates_dirty_buffer_attribute_only_after_change
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    geometry = Three::BufferGeometry.new
    position = Three::Float32BufferAttribute.new([0, 0, 0, 1, 0, 0, 0, 1, 0], 3)
    geometry.set_attribute(:position, position)

    backend.sync(geometry)
    adapter.calls.clear
    backend.sync(geometry)

    assert_empty adapter.calls

    position.set_x(0, 2)
    backend.sync(geometry)

    assert_equal :set_geometry_attribute, adapter.calls.last[0]
    assert_equal [2, 0, 0, 1, 0, 0, 0, 1, 0], adapter.calls.last[3][:array]
  end
end
