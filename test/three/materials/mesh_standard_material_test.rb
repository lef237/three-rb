# frozen_string_literal: true

require "test_helper"

class ThreeMeshStandardMaterialTest < Minitest::Test
  def test_defaults
    material = Three::MeshStandardMaterial.new

    assert_equal "MeshStandardMaterial", material.type
    assert_equal 0xffffff, material.color.hex
    assert_equal 1, material.roughness
    assert_equal 0, material.metalness
    assert_empty material.textures
    assert_nil material.normal_map
    assert_nil material.roughness_map
    assert_nil material.metalness_map
    refute material.wireframe
    refute material.flat_shading
    assert material.fog
  end

  def test_accepts_parameters
    texture = Three::Texture.new("/texture.png")
    normal_map = Three::Texture.new("/normal.png")
    roughness_map = Three::Texture.new("/roughness.png")
    metalness_map = Three::Texture.new("/metalness.png")
    material = Three::MeshStandardMaterial.new(
      color: 0x00ff00,
      roughness: 0.35,
      metalness: 0.7,
      map: texture,
      normal_map: normal_map,
      roughness_map: roughness_map,
      metalness_map: metalness_map,
      wireframe: true,
      flat_shading: true,
      opacity: 0.25,
      transparent: true
    )

    assert_equal 0x00ff00, material.color.hex
    assert_equal 0.35, material.roughness
    assert_equal 0.7, material.metalness
    assert_same texture, material.map
    assert_same normal_map, material.normal_map
    assert_same roughness_map, material.roughness_map
    assert_same metalness_map, material.metalness_map
    assert_equal [texture, metalness_map, normal_map, roughness_map], material.textures
    assert material.wireframe
    assert material.flat_shading
    assert_equal 0.25, material.opacity
    assert material.transparent
  end

  def test_marks_dirty_when_pbr_parameters_change
    material = Three::MeshStandardMaterial.new
    material.mark_clean!

    material.roughness = 0.2
    material.metalness = 0.8

    assert material.dirty_field?(:parameters)
    assert_equal 0.2, material.roughness
    assert_equal 0.8, material.metalness
  end

  def test_marks_dirty_when_color_changes
    material = Three::MeshStandardMaterial.new(color: 0xff0000)
    material.mark_clean!

    material.color.set_hex(0x00ff00)

    assert material.dirty_field?(:parameters)
  end

  def test_marks_dirty_when_map_changes
    material = Three::MeshStandardMaterial.new
    material.mark_clean!

    material.map = Three::Texture.new("/texture.png")

    assert material.dirty_field?(:parameters)
  end

  def test_marks_dirty_when_additional_texture_slot_changes
    material = Three::MeshStandardMaterial.new
    material.mark_clean!

    material.normal_map = Three::Texture.new("/normal.png")

    assert material.dirty_field?(:parameters)
  end

  def test_to_h
    material = Three::MeshStandardMaterial.new(
      color: 0x112233,
      roughness: 0.45,
      metalness: 0.25,
      map: Three::Texture.new("/texture.png"),
      normal_map: Three::Texture.new("/normal.png"),
      roughness_map: Three::Texture.new("/roughness.png"),
      flat_shading: true
    )

    assert_equal "MeshStandardMaterial", material.to_h[:type]
    assert_equal 0x112233, material.to_h[:color]
    assert_equal 0.45, material.to_h[:roughness]
    assert_equal 0.25, material.to_h[:metalness]
    assert_equal "/texture.png", material.to_h[:map][:source]
    assert_equal "/normal.png", material.to_h[:normal_map][:source]
    assert_equal "/roughness.png", material.to_h[:roughness_map][:source]
    assert material.to_h[:flat_shading]
  end
end
