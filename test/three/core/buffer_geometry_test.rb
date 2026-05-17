# frozen_string_literal: true

require "test_helper"

class ThreeBufferGeometryTest < Minitest::Test
  def test_set_index_from_array_chooses_uint16_for_small_indices
    geometry = Three::BufferGeometry.new.set_index([0, 1, 2])

    assert_instance_of Three::Uint16BufferAttribute, geometry.index
    assert_equal [0, 1, 2], geometry.index.array
  end

  def test_set_index_from_array_chooses_uint32_for_large_indices
    geometry = Three::BufferGeometry.new.set_index([0, 70_000])

    assert_instance_of Three::Uint32BufferAttribute, geometry.index
  end

  def test_attributes
    geometry = Three::BufferGeometry.new
    attribute = Three::Float32BufferAttribute.new([0, 0, 0], 3)

    geometry.set_attribute(:position, attribute)

    assert geometry.has_attribute?(:position)
    assert_same attribute, geometry.get_attribute("position")

    geometry.delete_attribute(:position)
    refute geometry.has_attribute?(:position)
  end

  def test_groups_and_draw_range
    geometry = Three::BufferGeometry.new

    geometry.add_group(0, 6, 1)
    geometry.set_draw_range(2, 4)

    assert_equal [{ start: 0, count: 6, material_index: 1 }], geometry.groups
    assert_equal({ start: 2, count: 4 }, geometry.draw_range)
  end

  def test_to_h_includes_name_for_json_round_trip
    geometry = Three::BufferGeometry.new
    geometry.name = "named-geometry"

    assert_equal "named-geometry", geometry.to_h[:name]
  end

  def test_to_h_includes_draw_range_and_user_data
    geometry = Three::BufferGeometry.new
    geometry.set_draw_range(2, 4)
    geometry.user_data = { "purpose" => "partial-draw" }

    assert_equal({ start: 2, count: 4 }, geometry.to_h[:draw_range])
    assert_equal({ "purpose" => "partial-draw" }, geometry.to_h[:user_data])
  end

  def test_compute_bounding_box_and_sphere
    geometry = Three::BufferGeometry.new
    geometry.set_attribute(:position, Three::Float32BufferAttribute.new([-1, -2, -3, 3, 2, 1], 3))

    geometry.compute_bounding_box
    geometry.compute_bounding_sphere

    assert_vector3_in_delta [-1, -2, -3], geometry.bounding_box[:min]
    assert_vector3_in_delta [3, 2, 1], geometry.bounding_box[:max]
    assert_vector3_in_delta [1, 0, -1], geometry.bounding_sphere[:center]
    assert_in_delta Math.sqrt(12), geometry.bounding_sphere[:radius], 1e-12
  end

  def test_center_marks_geometry_operation_dirty
    geometry = Three::BufferGeometry.new
    geometry.mark_clean!

    assert_same geometry, geometry.center
    assert geometry.centered?
    assert geometry.dirty_field?(:geometry_operations)
  end

  def test_dispose_event
    geometry = Three::BufferGeometry.new
    called = false
    geometry.on(:dispose) { called = true }

    geometry.dispose

    assert called
  end
end
