# frozen_string_literal: true

require "test_helper"

class ThreeOrthographicCameraTest < Minitest::Test
  def test_defaults
    camera = Three::OrthographicCamera.new

    assert_equal "OrthographicCamera", camera.type
    assert_equal(-1, camera.left)
    assert_equal 1, camera.right
    assert_equal 1, camera.top
    assert_equal(-1, camera.bottom)
    assert_equal 0.1, camera.near
    assert_equal 2000, camera.far
    assert_equal 1, camera.zoom
  end

  def test_projection_matrix_matches_symmetric_frustum
    camera = Three::OrthographicCamera.new(-2, 2, 1, -1, near: 1, far: 101)

    assert_in_delta 0.5, camera.projection_matrix.elements[0], 1e-12
    assert_in_delta 1, camera.projection_matrix.elements[5], 1e-12
    assert_in_delta(-0.02, camera.projection_matrix.elements[10], 1e-12)
    assert_in_delta(-1.02, camera.projection_matrix.elements[14], 1e-12)
    assert_equal 1, camera.projection_matrix.elements[15]
  end

  def test_zoom_changes_projection
    camera = Three::OrthographicCamera.new(-2, 2, 1, -1, near: 1, far: 101)
    before = camera.projection_matrix.to_a

    camera.zoom = 2
    camera.update_projection_matrix

    refute_equal before, camera.projection_matrix.to_a
    assert_in_delta 1, camera.projection_matrix.elements[0], 1e-12
    assert_in_delta 2, camera.projection_matrix.elements[5], 1e-12
  end

  def test_view_offset_changes_projection
    camera = Three::OrthographicCamera.new(-2, 2, 1, -1, near: 1, far: 101)
    before = camera.projection_matrix.to_a

    camera.set_view_offset(4, 2, 2, 0, 2, 2)

    refute_equal before, camera.projection_matrix.to_a
    assert_equal true, camera.view[:enabled]
  end
end
