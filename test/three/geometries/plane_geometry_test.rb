# frozen_string_literal: true

require "test_helper"

class ThreePlaneGeometryTest < Minitest::Test
  def test_builds_unit_plane_buffers
    geometry = Three::PlaneGeometry.new(1, 1)

    assert_equal "PlaneGeometry", geometry.type
    assert_equal 6, geometry.index.array.length
    assert_equal 4, geometry.get_attribute(:position).count
    assert_equal 4, geometry.get_attribute(:normal).count
    assert_equal 4, geometry.get_attribute(:uv).count
    assert_empty geometry.groups
  end

  def test_bounding_box
    geometry = Three::PlaneGeometry.new(2, 4)

    geometry.compute_bounding_box

    assert_vector3_in_delta [-1, -2, 0], geometry.bounding_box[:min]
    assert_vector3_in_delta [1, 2, 0], geometry.bounding_box[:max]
  end

  def test_segments_increase_vertex_and_index_counts
    geometry = Three::PlaneGeometry.new(1, 1, width_segments: 2, height_segments: 3)

    assert_equal 36, geometry.index.array.length
    assert_equal 12, geometry.get_attribute(:position).count
  end

  def test_unit_plane_positions_match_threejs_orientation
    geometry = Three::PlaneGeometry.new(2, 2)

    assert_equal [-1.0, 1.0, 0, 1.0, 1.0, 0, -1.0, -1.0, 0, 1.0, -1.0, 0], geometry.get_attribute(:position).array
    assert_equal [0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1], geometry.get_attribute(:normal).array
    assert_equal [0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 1.0, 0.0], geometry.get_attribute(:uv).array
  end
end
