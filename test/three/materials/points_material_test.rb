# frozen_string_literal: true

require "test_helper"

class ThreePointsMaterialTest < Minitest::Test
  def test_defaults
    material = Three::PointsMaterial.new

    assert_equal "PointsMaterial", material.type
    assert_equal 0xffffff, material.color.hex
    assert_nil material.map
    assert_nil material.alpha_map
    assert_equal 1, material.size
    assert material.size_attenuation
    assert material.fog
  end

  def test_accepts_parameters_and_tracks_textures
    map = Three::Texture.new("/points.png")
    alpha_map = Three::Texture.new("/points-alpha.png")
    material = Three::PointsMaterial.new(color: 0x66ddff, map: map, alpha_map: alpha_map, size: 0.4, size_attenuation: false, fog: false)

    assert_equal 0x66ddff, material.color.hex
    assert_same map, material.map
    assert_same alpha_map, material.alpha_map
    assert_equal [map, alpha_map], material.textures
    assert_equal 0.4, material.size
    refute material.size_attenuation
    refute material.fog
  end

  def test_marks_dirty_when_texture_changes
    material = Three::PointsMaterial.new
    material.mark_clean!

    material.alpha_map = Three::Texture.new("/points-alpha.png")

    assert material.dirty_field?(:parameters)
  end
end
