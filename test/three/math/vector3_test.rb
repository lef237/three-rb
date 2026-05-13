# frozen_string_literal: true

require "test_helper"

class ThreeVector3Test < Minitest::Test
  def test_initializes_to_zero_by_default
    assert_equal [0, 0, 0], Three::Vector3.new.to_a
  end

  def test_set_mutates_and_returns_self
    vector = Three::Vector3.new

    assert_same vector, vector.set(1, 2, 3)
    assert_equal [1, 2, 3], vector.to_a
  end

  def test_clone_returns_distinct_vector
    vector = Three::Vector3.new(1, 2, 3)
    clone = vector.clone

    assert_equal vector, clone
    refute_same vector, clone
  end

  def test_copy_reads_components
    source = Three::Vector3.new(4, 5, 6)
    target = Three::Vector3.new

    assert_same target, target.copy(source)
    assert_equal [4, 5, 6], target.to_a
  end

  def test_add_and_subtract_mutate_self
    vector = Three::Vector3.new(1, 2, 3)

    vector.add(Three::Vector3.new(4, 5, 6))
    assert_equal [5, 7, 9], vector.to_a

    vector.sub(Three::Vector3.new(1, 2, 3))
    assert_equal [4, 5, 6], vector.to_a
  end

  def test_operators_return_new_vectors
    a = Three::Vector3.new(1, 2, 3)
    b = Three::Vector3.new(4, 5, 6)

    assert_equal [5, 7, 9], (a + b).to_a
    assert_equal [-3, -3, -3], (a - b).to_a
    assert_equal [2, 4, 6], (a * 2).to_a
    assert_equal [0.5, 1.0, 1.5], (a / 2).to_a
    assert_equal [1, 2, 3], a.to_a
  end

  def test_divide_uses_float_division
    vector = Three::Vector3.new(1, 3, 5)

    vector.divide(Three::Vector3.new(2, 2, 2))

    assert_equal [0.5, 1.5, 2.5], vector.to_a
  end

  def test_dot_cross_and_lengths
    x_axis = Three::Vector3.new(1, 0, 0)
    y_axis = Three::Vector3.new(0, 1, 0)

    assert_equal 0, x_axis.dot(y_axis)
    assert_equal [0, 0, 1], x_axis.clone.cross(y_axis).to_a
    assert_equal 9, Three::Vector3.new(1, 2, 2).length_sq
    assert_equal 3, Three::Vector3.new(1, 2, 2).length
  end

  def test_normalize
    vector = Three::Vector3.new(3, 0, 4)

    vector.normalize

    assert_in_delta 1.0, vector.length, 1e-12
    assert_in_delta 0.6, vector.x, 1e-12
    assert_in_delta 0.0, vector.y, 1e-12
    assert_in_delta 0.8, vector.z, 1e-12
  end

  def test_component_access
    vector = Three::Vector3.new(1, 2, 3)

    assert_equal 2, vector[1]
    vector[1] = 5
    assert_equal [1, 5, 3], vector.to_a
    assert_raises(IndexError) { vector[3] }
  end

  def test_equals_with_epsilon
    a = Three::Vector3.new(1.0, 2.0, 3.0)
    b = Three::Vector3.new(1.001, 2.001, 3.001)

    refute a.equals?(b)
    assert a.equals?(b, epsilon: 0.01)
  end

  def test_apply_quaternion
    quaternion = Three::Quaternion.new.set_from_axis_angle(Three::Vector3.new(0, 1, 0), Math::PI / 2)
    vector = Three::Vector3.new(1, 0, 0)

    vector.apply_quaternion(quaternion)

    assert_vector3_in_delta [0, 0, -1], vector
  end

  def test_apply_matrix3
    matrix = Three::Matrix3.new.set(
      1, 2, 3,
      4, 5, 6,
      7, 8, 9
    )
    vector = Three::Vector3.new(1, 1, 1)

    assert_same vector, vector.apply_matrix3(matrix)
    assert_vector3_in_delta [6, 15, 24], vector
  end

  def test_matrix_array_helpers
    matrix = Three::Matrix4.new.make_translation(1, 2, 3)
    vector = Three::Vector3.new.set_from_matrix_position(matrix)

    assert_equal [1, 2, 3], vector.to_a
    assert_equal [nil, 1, 2, 3], vector.to_array([nil], 1)
  end

  def test_set_from_matrix3_column
    matrix = Three::Matrix3.new.set(
      1, 2, 3,
      4, 5, 6,
      7, 8, 9
    )
    vector = Three::Vector3.new

    vector.set_from_matrix3_column(matrix, 1)

    assert_vector3_in_delta [2, 5, 8], vector
  end
end
