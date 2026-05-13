# frozen_string_literal: true

require "test_helper"

class ThreeEulerTest < Minitest::Test
  def test_defaults_to_xyz_order
    assert_equal [0, 0, 0, "XYZ"], Three::Euler.new.to_a
  end

  def test_rejects_unknown_order
    assert_raises(ArgumentError) { Three::Euler.new(0, 0, 0, "BAD") }
  end

  def test_set_from_quaternion_round_trips_xyz_rotation
    source = Three::Euler.new(0.25, -0.5, 0.75, "XYZ")
    quaternion = Three::Quaternion.new.set_from_euler(source)
    result = Three::Euler.new.set_from_quaternion(quaternion, "XYZ")

    assert_in_delta source.x, result.x, 1e-12
    assert_in_delta source.y, result.y, 1e-12
    assert_in_delta source.z, result.z, 1e-12
    assert_equal "XYZ", result.order
  end

  def test_on_change_callback
    calls = 0
    euler = Three::Euler.new
    euler.on_change { calls += 1 }

    euler.y = 1

    assert_equal 1, calls
  end
end
