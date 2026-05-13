# frozen_string_literal: true

require "test_helper"

class ThreeMatrix3Test < Minitest::Test
  def test_defaults_to_identity
    assert_equal [
      1, 0, 0,
      0, 1, 0,
      0, 0, 1
    ], Three::Matrix3.new.elements
  end

  def test_set_accepts_row_major_values_and_stores_column_major
    matrix = Three::Matrix3.new.set(
      11, 12, 13,
      21, 22, 23,
      31, 32, 33
    )

    assert_equal [
      11, 21, 31,
      12, 22, 32,
      13, 23, 33
    ], matrix.elements
  end

  def test_multiply_matrices
    a = Three::Matrix3.new.set(
      1, 2, 3,
      4, 5, 6,
      7, 8, 9
    )
    b = Three::Matrix3.new.set(
      9, 8, 7,
      6, 5, 4,
      3, 2, 1
    )

    result = Three::Matrix3.new.multiply_matrices(a, b)

    assert_equal [
      30, 84, 138,
      24, 69, 114,
      18, 54, 90
    ], result.elements
  end

  def test_determinant_and_invert
    matrix = Three::Matrix3.new.set(
      1, 2, 3,
      0, 1, 4,
      5, 6, 0
    )
    inverse = matrix.clone.invert
    product = matrix.clone.multiply(inverse)

    assert_equal 1, matrix.determinant
    assert_matrix3_in_delta Three::Matrix3.new.elements, product.elements
  end

  def test_invert_sets_zero_matrix_for_singular_matrix
    matrix = Three::Matrix3.new.set(
      1, 2, 3,
      2, 4, 6,
      3, 6, 9
    )

    matrix.invert

    assert_equal Array.new(9, 0), matrix.elements
  end

  def test_set_from_matrix4_and_normal_matrix
    matrix4 = Three::Matrix4.new.make_scale(2, 3, 4)

    matrix = Three::Matrix3.new.set_from_matrix4(matrix4)
    normal = Three::Matrix3.new.get_normal_matrix(matrix4)

    assert_equal [
      2, 0, 0,
      0, 3, 0,
      0, 0, 4
    ], matrix.elements
    assert_matrix3_in_delta [
      0.5, 0, 0,
      0, 1.0 / 3, 0,
      0, 0, 0.25
    ], normal.elements
  end

  def test_uv_transform_matches_threejs_layout
    matrix = Three::Matrix3.new.set_uv_transform(1, 2, 3, 4, 0, 0.5, 0.25)

    assert_matrix3_in_delta [
      3, 0, 0,
      0, 4, 0,
      0, 1.25, 1
    ], matrix.elements
  end

  def test_transpose_and_transpose_into_array
    matrix = Three::Matrix3.new.set(
      1, 2, 3,
      4, 5, 6,
      7, 8, 9
    )

    array = matrix.transpose_into_array
    matrix.transpose

    assert_equal [1, 2, 3, 4, 5, 6, 7, 8, 9], array
    assert_equal [
      1, 2, 3,
      4, 5, 6,
      7, 8, 9
    ], matrix.elements
  end

  private

  def assert_matrix3_in_delta(expected, actual, delta = 1e-12)
    expected.each_with_index do |value, index|
      assert_in_delta value, actual[index], delta
    end
  end
end
