# frozen_string_literal: true

require "test_helper"

class ThreeShadowMaterialTest < Minitest::Test
  def test_defaults
    material = Three::ShadowMaterial.new

    assert_equal "ShadowMaterial", material.type
    assert_equal 0x000000, material.color.hex
    assert material.transparent
    assert_equal 1, material.opacity
    assert material.fog
  end

  def test_accepts_parameters
    material = Three::ShadowMaterial.new(color: 0x223344, opacity: 0.32, fog: false)

    assert_equal 0x223344, material.color.hex
    assert_equal 0.32, material.opacity
    assert material.transparent
    refute material.fog
  end

  def test_marks_dirty_when_color_changes
    material = Three::ShadowMaterial.new(color: 0x000000)
    material.mark_clean!

    material.color.set_hex(0x112233)

    assert material.dirty_field?(:parameters)
  end

  def test_marks_dirty_when_fog_changes
    material = Three::ShadowMaterial.new
    material.mark_clean!

    material.fog = false

    assert material.dirty_field?(:parameters)
  end

  def test_serializes_to_hash
    material = Three::ShadowMaterial.new(color: 0x112233, opacity: 0.4, fog: false)

    assert_equal "ShadowMaterial", material.to_h[:type]
    assert_equal 0x112233, material.to_h[:color]
    assert_equal 0.4, material.to_h[:opacity]
    assert material.to_h[:transparent]
    refute material.to_h[:fog]
  end
end
