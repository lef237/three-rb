# frozen_string_literal: true

require "test_helper"

class ThreeSpriteTest < Minitest::Test
  def test_defaults
    sprite = Three::Sprite.new

    assert_equal "Sprite", sprite.type
    assert_instance_of Three::SpriteMaterial, sprite.material
    assert_equal [0.5, 0.5], sprite.center.to_a
  end

  def test_accepts_material_and_center
    material = Three::SpriteMaterial.new(color: 0xffcc4d)
    sprite = Three::Sprite.new(material)
    sprite.center = [0.25, 0.75]

    assert_same material, sprite.material
    assert_equal [0.25, 0.75], sprite.center.to_a
  end

  def test_marks_dirty_when_material_or_center_changes
    sprite = Three::Sprite.new
    sprite.mark_clean!

    sprite.material = Three::SpriteMaterial.new(color: 0x66ddff)
    sprite.center.set(0.2, 0.8)

    assert sprite.dirty_field?(:sprite)
  end

  def test_rejects_invalid_center
    sprite = Three::Sprite.new

    assert_raises(TypeError) { sprite.center = [1, 2, 3] }
  end

  def test_to_h
    material = Three::SpriteMaterial.new(color: 0xffcc4d)
    sprite = Three::Sprite.new(material)
    sprite.center = [0.25, 0.75]

    assert_equal "Sprite", sprite.to_h[:type]
    assert_equal material.uuid, sprite.to_h[:material]
    assert_equal [0.25, 0.75], sprite.to_h[:center]
  end
end
