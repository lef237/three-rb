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

  def test_materializes_mesh_normal_material
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    material = Three::MeshNormalMaterial.new(flat_shading: true, wireframe: true)

    handle = backend.materialize(material)

    assert_equal :mesh_normal_material, handle[:type]
    assert_equal true, handle[:parameters][:flatShading]
    assert_equal true, handle[:parameters][:wireframe]
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

  def test_materializes_texture
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    texture = Three::Texture.new(
      "/texture.png",
      flip_y: false,
      wrap_s: Three::RepeatWrapping,
      wrap_t: Three::MirroredRepeatWrapping,
      mag_filter: Three::NearestFilter,
      min_filter: Three::NearestMipmapNearestFilter,
      repeat: [2, 3]
    )

    handle = backend.materialize(texture)

    assert_equal :texture, handle[:type]
    assert_equal "/texture.png", handle[:source]
    assert_equal false, handle[:flip_y]
    assert_equal Three::RepeatWrapping, handle[:wrap_s]
    assert_equal Three::MirroredRepeatWrapping, handle[:wrap_t]
    assert_equal Three::NearestFilter, handle[:mag_filter]
    assert_equal Three::NearestMipmapNearestFilter, handle[:min_filter]
    assert_equal [2, 3], handle[:repeat]
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
    assert_equal false, handle[:flip_y]
    assert_equal Three::ClampToEdgeWrapping, handle[:wrap_s]
    assert_equal Three::ClampToEdgeWrapping, handle[:wrap_t]
    assert_equal Three::LinearFilter, handle[:mag_filter]
    assert_equal Three::LinearMipmapLinearFilter, handle[:min_filter]
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
    backend.sync(texture)

    assert_equal :update_texture, adapter.calls.last[0]
    assert_same handle, adapter.calls.last[1]
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
    assert_equal [1, 2, 3], handle[:position]
    assert_equal [2, 2, 2], handle[:scale]
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
    material = Three::MeshStandardMaterial.new(map: texture, normal_map: normal_map, roughness_map: texture)

    material_handle = backend.materialize(material)
    texture_handle = backend.materialize(texture)
    normal_map_handle = backend.materialize(normal_map)
    adapter.calls.clear

    disposed_material = backend.dispose(material, dispose_textures: true)

    assert_same material_handle, disposed_material
    assert_equal [
      [:dispose, texture_handle],
      [:dispose, normal_map_handle],
      [:dispose, material_handle]
    ], adapter.calls
    refute backend.handles.key?(material.uuid)
    refute backend.handles.key?(texture.uuid)
    refute backend.handles.key?(normal_map.uuid)
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

    assert_equal [:update_texture, roughness_map_handle, {
      flip_y: true,
      wrap_s: Three::ClampToEdgeWrapping,
      wrap_t: Three::ClampToEdgeWrapping,
      mag_filter: Three::LinearFilter,
      min_filter: Three::LinearMipmapLinearFilter,
      repeat: [2, 2]
    }], adapter.calls.last
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
