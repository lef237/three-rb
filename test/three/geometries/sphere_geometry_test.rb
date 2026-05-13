# frozen_string_literal: true

require "test_helper"

class ThreeSphereGeometryTest < Minitest::Test
  def test_builds_unit_sphere_buffers
    geometry = Three::SphereGeometry.new(1, width_segments: 3, height_segments: 2)

    assert_equal "SphereGeometry", geometry.type
    assert_equal 18, geometry.index.array.length
    assert_equal 12, geometry.get_attribute(:position).count
    assert_equal 12, geometry.get_attribute(:normal).count
    assert_equal 12, geometry.get_attribute(:uv).count
    assert_empty geometry.groups
  end

  def test_segments_are_clamped
    geometry = Three::SphereGeometry.new(1, width_segments: 1, height_segments: 1)

    assert_equal 18, geometry.index.array.length
    assert_equal 12, geometry.get_attribute(:position).count
  end

  def test_bounding_box
    geometry = Three::SphereGeometry.new(2, width_segments: 32, height_segments: 16)

    geometry.compute_bounding_box

    assert_vector3_in_delta [-2, -2, -2], geometry.bounding_box[:min]
    assert_vector3_in_delta [2, 2, 2], geometry.bounding_box[:max]
  end

  def test_normals_are_unit_length
    geometry = Three::SphereGeometry.new(1, width_segments: 8, height_segments: 4)
    normal = geometry.get_attribute(:normal)

    normal.count.times do |index|
      length = Math.sqrt(
        normal.get_x(index) * normal.get_x(index) +
        normal.get_y(index) * normal.get_y(index) +
        normal.get_z(index) * normal.get_z(index)
      )
      assert_in_delta 1, length, 1e-12
    end
  end

  def test_partial_sphere_parameters_are_preserved
    geometry = Three::SphereGeometry.new(3, width_segments: 12, height_segments: 6, phi_start: 0.5, phi_length: 1.0, theta_start: 0.25, theta_length: 2.0)

    assert_equal 3, geometry.parameters[:radius]
    assert_equal 12, geometry.parameters[:width_segments]
    assert_equal 6, geometry.parameters[:height_segments]
    assert_equal 0.5, geometry.parameters[:phi_start]
    assert_equal 1.0, geometry.parameters[:phi_length]
    assert_equal 0.25, geometry.parameters[:theta_start]
    assert_equal 2.0, geometry.parameters[:theta_length]
  end
end
