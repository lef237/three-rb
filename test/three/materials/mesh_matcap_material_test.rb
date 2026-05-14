# frozen_string_literal: true

require "test_helper"

class ThreeMeshMatcapMaterialTest < Minitest::Test
  def test_defaults
    material = Three::MeshMatcapMaterial.new

    assert_equal "MeshMatcapMaterial", material.type
    assert_equal 0xffffff, material.color.hex
    assert_nil material.matcap
    refute material.wireframe
    refute material.flat_shading
    assert material.fog
  end

  def test_accepts_parameters
    matcap = Three::Texture.new("/matcap.png")
    texture = Three::Texture.new("/texture.png")
    material = Three::MeshMatcapMaterial.new(
      color: 0x99ccff,
      matcap: matcap,
      map: texture,
      wireframe: true,
      flat_shading: true,
      opacity: 0.7,
      transparent: true
    )

    assert_equal 0x99ccff, material.color.hex
    assert_same matcap, material.matcap
    assert_same texture, material.map
    assert material.wireframe
    assert material.flat_shading
    assert_equal 0.7, material.opacity
    assert material.transparent
  end

  def test_marks_dirty_when_color_changes
    material = Three::MeshMatcapMaterial.new(color: 0xff0000)
    material.mark_clean!

    material.color.set_hex(0x00ff00)

    assert material.dirty_field?(:parameters)
  end

  def test_marks_dirty_when_texture_slot_changes
    material = Three::MeshMatcapMaterial.new
    material.mark_clean!

    material.matcap = Three::Texture.new("/matcap.png")

    assert material.dirty_field?(:parameters)
  end

  def test_tracks_unique_texture_slots
    shared = Three::Texture.new("/shared.png")
    normal_map = Three::Texture.new("/normal.png")
    material = Three::MeshMatcapMaterial.new(matcap: shared, map: shared, normal_map: normal_map)

    assert_equal %i[matcap map alpha_map bump_map displacement_map normal_map], material.texture_slots
    assert_equal [shared, normal_map], material.textures
  end

  def test_serializes_to_hash
    matcap = Three::Texture.new("/matcap.png")
    material = Three::MeshMatcapMaterial.new(color: 0x112233, matcap: matcap, flat_shading: true)

    assert_equal "MeshMatcapMaterial", material.to_h[:type]
    assert_equal 0x112233, material.to_h[:color]
    assert_equal "/matcap.png", material.to_h[:matcap][:source]
    assert material.to_h[:flat_shading]
  end
end
