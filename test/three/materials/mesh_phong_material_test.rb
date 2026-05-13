# frozen_string_literal: true

require "test_helper"

class ThreeMeshPhongMaterialTest < Minitest::Test
  def test_defaults
    material = Three::MeshPhongMaterial.new

    assert_equal "MeshPhongMaterial", material.type
    assert_equal 0xffffff, material.color.hex
    assert_equal 0x111111, material.specular.hex
    assert_equal 0x000000, material.emissive.hex
    assert_equal 30, material.shininess
    assert_empty material.textures
    refute material.wireframe
    refute material.flat_shading
    assert material.fog
  end

  def test_accepts_parameters
    texture = Three::Texture.new("/texture.png")
    specular_map = Three::Texture.new("/specular.png")
    normal_map = Three::Texture.new("/normal.png")
    material = Three::MeshPhongMaterial.new(
      color: 0x224466,
      specular: 0xf0f6ff,
      emissive: 0x111827,
      shininess: 72,
      map: texture,
      specular_map: specular_map,
      normal_map: normal_map,
      flat_shading: true,
      transparent: true,
      opacity: 0.8
    )

    assert_equal 0x224466, material.color.hex
    assert_equal 0xf0f6ff, material.specular.hex
    assert_equal 0x111827, material.emissive.hex
    assert_equal 72, material.shininess
    assert_same texture, material.map
    assert_same specular_map, material.specular_map
    assert_same normal_map, material.normal_map
    assert_equal [texture, normal_map, specular_map], material.textures
    assert material.flat_shading
    assert material.transparent
    assert_equal 0.8, material.opacity
  end

  def test_marks_dirty_when_specular_parameters_change
    material = Three::MeshPhongMaterial.new
    material.mark_clean!

    material.specular.set_hex(0xffffff)
    material.shininess = 96

    assert material.dirty_field?(:parameters)
    assert_equal 0xffffff, material.specular.hex
    assert_equal 96, material.shininess
  end

  def test_marks_dirty_when_texture_slot_changes
    material = Three::MeshPhongMaterial.new
    material.mark_clean!

    material.specular_map = Three::Texture.new("/specular.png")

    assert material.dirty_field?(:parameters)
  end

  def test_to_h
    material = Three::MeshPhongMaterial.new(
      color: 0x112233,
      specular: 0xeeeeff,
      emissive: 0x010203,
      shininess: 48,
      map: Three::Texture.new("/texture.png"),
      specular_map: Three::Texture.new("/specular.png"),
      flat_shading: true
    )

    assert_equal "MeshPhongMaterial", material.to_h[:type]
    assert_equal 0x112233, material.to_h[:color]
    assert_equal 0xeeeeff, material.to_h[:specular]
    assert_equal 0x010203, material.to_h[:emissive]
    assert_equal 48, material.to_h[:shininess]
    assert_equal "/texture.png", material.to_h[:map][:source]
    assert_equal "/specular.png", material.to_h[:specular_map][:source]
    assert material.to_h[:flat_shading]
  end
end
