# frozen_string_literal: true

require "test_helper"

class ThreeCameraTest < Minitest::Test
  def test_matrix_world_inverse_is_updated
    camera = Three::Camera.new
    camera.position.set(1, 2, 3)

    camera.update_matrix_world

    origin_in_camera_space = Three::Vector3.new(1, 2, 3).apply_matrix4(camera.matrix_world_inverse)
    assert_vector3_in_delta [0, 0, 0], origin_in_camera_space
  end

  def test_world_direction_points_down_negative_z
    camera = Three::Camera.new

    assert_vector3_in_delta [0, 0, -1], camera.get_world_direction
  end
end
