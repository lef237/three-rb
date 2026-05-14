# frozen_string_literal: true

require "test_helper"

class ThreeMeshToonMaterialTest < Minitest::Test
  def test_defaults
    material = Three::MeshToonMaterial.new

    assert_equal "MeshToonMaterial", material.type
    assert_equal 0xffffff, material.color.hex
    assert_equal 0x000000, material.emissive.hex
    assert_empty material.textures
    refute material.wireframe
    refute material.flat_shading
    assert material.fog
  end

  def test_accepts_parameters
    texture = Three::Texture.new("/texture.png")
    gradient_map = Three::Texture.new("/gradient.png")
    emissive_map = Three::Texture.new("/emissive.png")
    material = Three::MeshToonMaterial.new(
      color: 0x99ccff,
      emissive: 0x101820,
      map: texture,
      gradient_map: gradient_map,
      emissive_map: emissive_map,
      wireframe: true,
      flat_shading: true,
      transparent: true,
      opacity: 0.8
    )

    assert_equal 0x99ccff, material.color.hex
    assert_equal 0x101820, material.emissive.hex
    assert_same texture, material.map
    assert_same gradient_map, material.gradient_map
    assert_same emissive_map, material.emissive_map
    assert_equal [texture, gradient_map, emissive_map], material.textures
    assert material.wireframe
    assert material.flat_shading
    assert material.transparent
    assert_equal 0.8, material.opacity
  end

  def test_marks_dirty_when_color_changes
    material = Three::MeshToonMaterial.new(color: 0xff0000, emissive: 0x000000)
    material.mark_clean!

    material.color.set_hex(0x00ff00)
    material.emissive.set_hex(0x111827)

    assert material.dirty_field?(:parameters)
  end

  def test_marks_dirty_when_texture_slot_changes
    material = Three::MeshToonMaterial.new
    material.mark_clean!

    material.gradient_map = Three::Texture.new("/gradient.png")

    assert material.dirty_field?(:parameters)
  end

  def test_tracks_unique_texture_slots
    shared = Three::Texture.new("/shared.png")
    normal_map = Three::Texture.new("/normal.png")
    material = Three::MeshToonMaterial.new(map: shared, gradient_map: shared, normal_map: normal_map)

    assert_equal %i[map gradient_map light_map ao_map emissive_map bump_map normal_map displacement_map alpha_map], material.texture_slots
    assert_equal [shared, normal_map], material.textures
  end

  def test_serializes_to_hash
    gradient_map = Three::Texture.new("/gradient.png")
    material = Three::MeshToonMaterial.new(color: 0x112233, emissive: 0x010203, gradient_map: gradient_map, flat_shading: true)

    assert_equal "MeshToonMaterial", material.to_h[:type]
    assert_equal 0x112233, material.to_h[:color]
    assert_equal 0x010203, material.to_h[:emissive]
    assert_equal "/gradient.png", material.to_h[:gradient_map][:source]
    assert material.to_h[:flat_shading]
  end
end
