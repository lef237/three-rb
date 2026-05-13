# frozen_string_literal: true

require "test_helper"

class ThreeMeshBasicMaterialTest < Minitest::Test
  def test_defaults
    material = Three::MeshBasicMaterial.new

    assert_equal "MeshBasicMaterial", material.type
    assert_equal 0xffffff, material.color.hex
    refute material.wireframe
    assert material.fog
  end

  def test_accepts_parameters
    texture = Three::Texture.new("/texture.png")
    material = Three::MeshBasicMaterial.new(color: 0x00ff00, map: texture, wireframe: true, opacity: 0.25, transparent: true)

    assert_equal 0x00ff00, material.color.hex
    assert_same texture, material.map
    assert material.wireframe
    assert_equal 0.25, material.opacity
    assert material.transparent
  end

  def test_marks_dirty_when_color_changes
    material = Three::MeshBasicMaterial.new(color: 0xff0000)
    material.mark_clean!

    material.color.set_hex(0x00ff00)

    assert material.dirty_field?(:parameters)
  end

  def test_marks_dirty_when_map_changes
    material = Three::MeshBasicMaterial.new
    material.mark_clean!

    material.map = Three::Texture.new("/texture.png")

    assert material.dirty_field?(:parameters)
  end
end
