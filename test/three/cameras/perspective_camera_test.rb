# frozen_string_literal: true

require "test_helper"

class ThreePerspectiveCameraTest < Minitest::Test
  def test_defaults
    camera = Three::PerspectiveCamera.new

    assert_equal "PerspectiveCamera", camera.type
    assert_equal 50, camera.fov
    assert_equal 1, camera.aspect
    assert_equal 0.1, camera.near
    assert_equal 2000, camera.far
  end

  def test_projection_matrix_matches_symmetric_frustum
    camera = Three::PerspectiveCamera.new(90, aspect: 1, near: 1, far: 100)

    assert_in_delta 1, camera.projection_matrix.elements[0], 1e-12
    assert_in_delta 1, camera.projection_matrix.elements[5], 1e-12
    assert_in_delta(-1.02020202020202, camera.projection_matrix.elements[10], 1e-12)
    assert_equal(-1, camera.projection_matrix.elements[11])
  end

  def test_focal_length_round_trip
    camera = Three::PerspectiveCamera.new(50, aspect: 2)
    focal_length = camera.focal_length

    camera.set_focal_length(focal_length)

    assert_in_delta 50, camera.fov, 1e-12
  end

  def test_view_offset_changes_projection
    camera = Three::PerspectiveCamera.new(90, aspect: 1, near: 1, far: 100)
    before = camera.projection_matrix.to_a

    camera.set_view_offset(2, 1, 1, 0, 1, 1)

    refute_equal before, camera.projection_matrix.to_a
  end
end
