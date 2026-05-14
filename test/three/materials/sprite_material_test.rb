# frozen_string_literal: true

require "test_helper"

class ThreeSpriteMaterialTest < Minitest::Test
  def test_defaults
    material = Three::SpriteMaterial.new

    assert_equal "SpriteMaterial", material.type
    assert_equal 0xffffff, material.color.hex
    assert_nil material.map
    assert_nil material.alpha_map
    assert_equal 0, material.rotation
    assert material.size_attenuation
    assert material.transparent
    assert material.fog
  end

  def test_accepts_parameters
    texture = Three::Texture.new("/sprite.png")
    alpha_map = Three::Texture.new("/alpha.png")
    material = Three::SpriteMaterial.new(
      color: 0xffcc4d,
      map: texture,
      alpha_map: alpha_map,
      rotation: 0.35,
      size_attenuation: false,
      opacity: 0.75,
      fog: false
    )

    assert_equal 0xffcc4d, material.color.hex
    assert_same texture, material.map
    assert_same alpha_map, material.alpha_map
    assert_equal [texture, alpha_map], material.textures
    assert_equal 0.35, material.rotation
    refute material.size_attenuation
    assert_equal 0.75, material.opacity
    refute material.fog
  end

  def test_marks_dirty_when_color_or_rotation_changes
    material = Three::SpriteMaterial.new
    material.mark_clean!

    material.color.set_hex(0x66ddff)
    material.rotation = 0.5

    assert material.dirty_field?(:parameters)
  end

  def test_marks_dirty_when_texture_slot_changes
    material = Three::SpriteMaterial.new
    material.mark_clean!

    material.map = Three::Texture.new("/sprite.png")

    assert material.dirty_field?(:parameters)
  end

  def test_to_h
    material = Three::SpriteMaterial.new(
      color: 0x112233,
      map: Three::Texture.new("/sprite.png"),
      rotation: 0.25,
      size_attenuation: false
    )

    assert_equal "SpriteMaterial", material.to_h[:type]
    assert_equal 0x112233, material.to_h[:color]
    assert_equal "/sprite.png", material.to_h[:map][:source]
    assert_equal 0.25, material.to_h[:rotation]
    refute material.to_h[:size_attenuation]
  end
end
