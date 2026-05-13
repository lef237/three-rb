# frozen_string_literal: true

require "test_helper"

class ThreeQuaternionTest < Minitest::Test
  def test_defaults_to_identity_rotation
    assert_equal [0, 0, 0, 1], Three::Quaternion.new.to_a
  end

  def test_set_from_axis_angle
    quaternion = Three::Quaternion.new
    axis = Three::Vector3.new(0, 1, 0)

    quaternion.set_from_axis_angle(axis, Math::PI / 2)

    half_sqrt = Math.sqrt(0.5)
    assert_quaternion_in_delta [0, half_sqrt, 0, half_sqrt], quaternion
  end

  def test_set_from_euler
    euler = Three::Euler.new(Math::PI / 2, 0, 0)
    quaternion = Three::Quaternion.new.set_from_euler(euler)

    half_sqrt = Math.sqrt(0.5)
    assert_quaternion_in_delta [half_sqrt, 0, 0, half_sqrt], quaternion
  end

  def test_multiply_quaternions
    x = Three::Quaternion.new.set_from_axis_angle(Three::Vector3.new(1, 0, 0), Math::PI / 2)
    y = Three::Quaternion.new.set_from_axis_angle(Three::Vector3.new(0, 1, 0), Math::PI / 2)

    combined = x.clone.multiply(y)

    assert_in_delta 1.0, combined.length, 1e-12
  end

  def test_normalize_zero_quaternion_returns_identity
    quaternion = Three::Quaternion.new(0, 0, 0, 0)

    quaternion.normalize

    assert_equal [0, 0, 0, 1], quaternion.to_a
  end

  def test_on_change_callback
    calls = 0
    quaternion = Three::Quaternion.new
    quaternion.on_change { calls += 1 }

    quaternion.x = 1

    assert_equal 1, calls
  end
end
