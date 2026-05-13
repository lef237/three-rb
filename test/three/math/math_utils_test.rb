# frozen_string_literal: true

require "test_helper"

class ThreeMathUtilsTest < Minitest::Test
  def test_clamp
    assert_equal 0, Three::MathUtils.clamp(-1, 0, 10)
    assert_equal 5, Three::MathUtils.clamp(5, 0, 10)
    assert_equal 10, Three::MathUtils.clamp(11, 0, 10)
  end

  def test_degree_radian_conversion
    assert_in_delta Math::PI, Three::MathUtils.deg_to_rad(180), 1e-12
    assert_in_delta 180, Three::MathUtils.rad_to_deg(Math::PI), 1e-12
  end

  def test_lerp
    assert_equal 15, Three::MathUtils.lerp(10, 20, 0.5)
  end
end
