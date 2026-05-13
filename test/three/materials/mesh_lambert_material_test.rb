# frozen_string_literal: true

require "test_helper"

class ThreeMeshLambertMaterialTest < Minitest::Test
  def test_defaults
    material = Three::MeshLambertMaterial.new

    assert_equal "MeshLambertMaterial", material.type
    assert_equal 0xffffff, material.color.hex
    refute material.wireframe
    refute material.flat_shading
    assert material.fog
  end

  def test_accepts_parameters
    texture = Three::Texture.new("/texture.png")
    material = Three::MeshLambertMaterial.new(color: 0x00ff00, map: texture, wireframe: true, flat_shading: true, opacity: 0.25, transparent: true)

    assert_equal 0x00ff00, material.color.hex
    assert_same texture, material.map
    assert material.wireframe
    assert material.flat_shading
    assert_equal 0.25, material.opacity
    assert material.transparent
  end

  def test_marks_dirty_when_color_changes
    material = Three::MeshLambertMaterial.new(color: 0xff0000)
    material.mark_clean!

    material.color.set_hex(0x00ff00)

    assert material.dirty_field?(:parameters)
  end

  def test_to_h
    material = Three::MeshLambertMaterial.new(color: 0x112233, map: Three::Texture.new("/texture.png"), flat_shading: true)

    assert_equal "MeshLambertMaterial", material.to_h[:type]
    assert_equal 0x112233, material.to_h[:color]
    assert_equal "/texture.png", material.to_h[:map][:source]
    assert material.to_h[:flat_shading]
  end
end
