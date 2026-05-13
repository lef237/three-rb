# frozen_string_literal: true

require "test_helper"

class ThreeRaycasterTest < Minitest::Test
  def test_set_from_camera_delegates_to_backend
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    camera = Three::PerspectiveCamera.new
    raycaster = Three::Raycaster.new(backend: backend)

    result = raycaster.set_from_camera(Three::Vector2.new(0.25, -0.5), camera)

    assert_same raycaster, result
    call = adapter.calls.find { |entry| entry[0] == :set_raycaster_from_camera }
    refute_nil call
    assert_same raycaster.handle, call[1]
    assert_equal [0.25, -0.5], call[2]
    assert_equal :perspective_camera, call[3][:type]
  end

  def test_intersect_objects_maps_hits_back_to_ruby_objects
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    mesh = Three::Mesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new)
    handle = backend.sync(mesh)
    raycaster = Three::Raycaster.new(backend: backend)
    adapter.calls.clear
    adapter.raycaster_intersections = [
      {
        distance: 3.5,
        point: [1, 2, 3],
        object: handle,
        uv: [0.25, 0.75],
        face_index: 4,
        index: 2,
        instance_id: 8
      }
    ]

    hits = raycaster.intersect_objects([mesh], recursive: true)

    assert_equal 1, hits.length
    hit = hits.first
    assert_equal 3.5, hit.distance
    assert_equal Three::Vector3.new(1, 2, 3), hit.point
    assert_same mesh, hit.object
    assert_same handle, hit.object_handle
    assert_equal Three::Vector2.new(0.25, 0.75), hit.uv
    assert_equal 4, hit.face_index
    assert_equal 2, hit.index
    assert_equal 8, hit.instance_id
    assert_same adapter.raycaster_intersections.first, hit.raw

    call = adapter.calls.find { |entry| entry[0] == :intersect_objects }
    refute_nil call
    assert_same raycaster.handle, call[1]
    assert_equal [handle], call[2]
    assert_equal true, call[3]
  end

  def test_intersect_object_accepts_single_object
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    mesh = Three::Mesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new)
    handle = backend.sync(mesh)
    raycaster = Three::Raycaster.new(backend: backend)
    adapter.raycaster_intersections = [{ distance: 1, point: [0, 0, 0], object: handle }]

    hits = raycaster.intersect_object(mesh)

    assert_equal 1, hits.length
    assert_same mesh, hits.first.object
  end

  def test_intersection_keeps_object_handle_when_ruby_object_is_unknown
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    unknown_handle = { type: :external_child }
    raycaster = Three::Raycaster.new(backend: backend)
    adapter.raycaster_intersections = [{ distance: 1, point: [0, 0, 0], object: unknown_handle }]

    hit = raycaster.intersect_objects([]).first

    assert_nil hit.object
    assert_same unknown_handle, hit.object_handle
  end

  def test_disposed_object_handle_is_not_mapped_back_to_ruby_object
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    mesh = Three::Mesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new)
    handle = backend.sync(mesh)
    backend.dispose(mesh)
    raycaster = Three::Raycaster.new(backend: backend)
    adapter.raycaster_intersections = [{ distance: 1, point: [0, 0, 0], object: handle }]

    hit = raycaster.intersect_objects([]).first

    assert_nil hit.object
    assert_same handle, hit.object_handle
  end

  def test_set_from_camera_rejects_invalid_coords
    raycaster = Three::Raycaster.new(backend: Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new))

    assert_raises(TypeError) { raycaster.set_from_camera([0, 1, 2], Three::PerspectiveCamera.new) }
  end
end
