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
end
