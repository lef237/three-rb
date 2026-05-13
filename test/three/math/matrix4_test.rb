# frozen_string_literal: true

require "test_helper"

class ThreeMatrix4Test < Minitest::Test
  def test_defaults_to_identity
    assert_equal [
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    ], Three::Matrix4.new.elements
  end

  def test_set_accepts_row_major_values_and_stores_column_major
    matrix = Three::Matrix4.new.set(
      11, 12, 13, 14,
      21, 22, 23, 24,
      31, 32, 33, 34,
      41, 42, 43, 44
    )

    assert_equal [
      11, 21, 31, 41,
      12, 22, 32, 42,
      13, 23, 33, 43,
      14, 24, 34, 44
    ], matrix.elements
  end

  def test_multiply_matrices
    parent = Three::Matrix4.new.make_translation(1, 2, 3)
    child = Three::Matrix4.new.make_translation(4, 5, 6)

    result = Three::Matrix4.new.multiply_matrices(parent, child)

    assert_equal [5, 7, 9], Three::Vector3.new.set_from_matrix_position(result).to_a
  end

  def test_compose_applies_position_rotation_and_scale
    position = Three::Vector3.new(1, 2, 3)
    rotation = Three::Quaternion.new.set_from_axis_angle(Three::Vector3.new(0, 1, 0), Math::PI / 2)
    scale = Three::Vector3.new(2, 3, 4)
    matrix = Three::Matrix4.new.compose(position, rotation, scale)

    result = Three::Vector3.new(1, 0, 0).apply_matrix4(matrix)

    assert_vector3_in_delta [1, 2, 1], result
  end

  def test_decompose_round_trips_composed_transform
    position = Three::Vector3.new(1, 2, 3)
    rotation = Three::Quaternion.new.set_from_axis_angle(Three::Vector3.new(0, 1, 0), Math::PI / 4)
    scale = Three::Vector3.new(2, 3, 4)
    matrix = Three::Matrix4.new.compose(position, rotation, scale)
    out_position = Three::Vector3.new
    out_rotation = Three::Quaternion.new
    out_scale = Three::Vector3.new

    matrix.decompose(out_position, out_rotation, out_scale)

    assert_vector3_in_delta [1, 2, 3], out_position
    assert_vector3_in_delta [2, 3, 4], out_scale
    assert_quaternion_in_delta rotation.to_a, out_rotation
  end

  def test_determinant
    assert_equal 1, Three::Matrix4.new.determinant
    assert_equal 24, Three::Matrix4.new.make_scale(2, 3, 4).determinant
  end

  def test_invert
    matrix = Three::Matrix4.new.make_translation(1, 2, 3)
    inverse = matrix.clone.invert
    vector = Three::Vector3.new(1, 2, 3).apply_matrix4(inverse)

    assert_vector3_in_delta [0, 0, 0], vector
  end

  def test_make_perspective
    matrix = Three::Matrix4.new.make_perspective(-1, 1, 1, -1, 1, 100)

    assert_in_delta 1, matrix.elements[0], 1e-12
    assert_in_delta 1, matrix.elements[5], 1e-12
    assert_in_delta(-1.02020202020202, matrix.elements[10], 1e-12)
    assert_equal(-1, matrix.elements[11])
  end

  def test_make_orthographic
    matrix = Three::Matrix4.new.make_orthographic(-2, 2, 1, -1, 1, 101)

    assert_in_delta 0.5, matrix.elements[0], 1e-12
    assert_in_delta 1, matrix.elements[5], 1e-12
    assert_in_delta(-0.02, matrix.elements[10], 1e-12)
    assert_in_delta(-1.02, matrix.elements[14], 1e-12)
    assert_equal 1, matrix.elements[15]
  end
end
