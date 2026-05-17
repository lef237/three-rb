# frozen_string_literal: true

require "test_helper"

class ThreeFogTest < Minitest::Test
  def test_fog_tracks_color_and_range
    fog = Three::Fog.new(0x112233, near: 2, far: 50, name: "mist")

    assert_equal "Fog", fog.type
    assert_equal "mist", fog.name
    assert_equal 0x112233, fog.color.hex
    assert_equal 2, fog.near
    assert_equal 50, fog.far
    assert_equal({ type: "Fog", name: "mist", color: 0x112233, near: 2, far: 50 }, fog.to_h)
  end

  def test_fog_exp2_tracks_density
    fog = Three::FogExp2.new(0x445566, density: 0.02, name: "haze")

    assert_equal "FogExp2", fog.type
    assert_equal 0x445566, fog.color.hex
    assert_equal 0.02, fog.density
    assert_equal({ type: "FogExp2", name: "haze", color: 0x445566, density: 0.02 }, fog.to_h)
  end

  def test_marks_dirty_when_color_changes
    fog = Three::Fog.new
    fog.mark_clean!

    fog.color.set_hex(0xff0000)

    assert fog.dirty_field?(:parameters)
  end
end
