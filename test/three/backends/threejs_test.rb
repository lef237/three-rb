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

  def test_materializes_texture
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    texture = Three::Texture.new("/texture.png", flip_y: false)

    handle = backend.materialize(texture)

    assert_equal :texture, handle[:type]
    assert_equal "/texture.png", handle[:source]
    assert_equal false, handle[:flip_y]
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

    assert_equal :ambient_light, ambient[:type]
    assert_equal 0x112233, ambient[:color]
    assert_equal 0.5, ambient[:intensity]
    assert_equal :directional_light, directional[:type]
    assert_equal 0xffffff, directional[:color]
    assert_equal 1.25, directional[:intensity]
  end

  def test_sync_updates_object_transform
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    object = Three::Object3D.new
    object.name = "node"
    object.position.set(1, 2, 3)
    object.scale.set(2, 2, 2)

    handle = backend.sync(object)

    assert_equal "node", handle[:name]
    assert_equal [1, 2, 3], handle[:position]
    assert_equal [2, 2, 2], handle[:scale]
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
