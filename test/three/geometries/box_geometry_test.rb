# frozen_string_literal: true

require "test_helper"

class ThreeBoxGeometryTest < Minitest::Test
  def test_builds_unit_box_buffers
    geometry = Three::BoxGeometry.new(1, 1, 1)

    assert_equal "BoxGeometry", geometry.type
    assert_equal 36, geometry.index.array.length
    assert_equal 24, geometry.get_attribute(:position).count
    assert_equal 24, geometry.get_attribute(:normal).count
    assert_equal 24, geometry.get_attribute(:uv).count
    assert_equal 6, geometry.groups.length
  end

  def test_bounding_box
    geometry = Three::BoxGeometry.new(1, 2, 3)

    geometry.compute_bounding_box

    assert_vector3_in_delta [-0.5, -1, -1.5], geometry.bounding_box[:min]
    assert_vector3_in_delta [0.5, 1, 1.5], geometry.bounding_box[:max]
  end

  def test_segments_increase_vertex_and_index_counts
    geometry = Three::BoxGeometry.new(1, 1, 1, width_segments: 2, height_segments: 2, depth_segments: 2)

    assert_equal 144, geometry.index.array.length
    assert_equal 54, geometry.get_attribute(:position).count
  end
end
