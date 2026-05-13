# frozen_string_literal: true

require "test_helper"

class ThreeMeshPhysicalMaterialTest < Minitest::Test
  def test_defaults
    material = Three::MeshPhysicalMaterial.new

    assert_equal "MeshPhysicalMaterial", material.type
    assert_equal 0xffffff, material.color.hex
    assert_equal 1, material.roughness
    assert_equal 0, material.metalness
    assert_equal 0, material.anisotropy
    assert_equal 0, material.anisotropy_rotation
    assert_equal 0, material.clearcoat
    assert_equal 0, material.clearcoat_roughness
    assert_equal 0, material.transmission
    assert_equal 0, material.thickness
    assert_equal 1.5, material.ior
    assert_equal 0.5, material.reflectivity
    assert_equal 0, material.iridescence
    assert_equal 1.3, material.iridescence_ior
    assert_equal [100, 400], material.iridescence_thickness_range
    assert_equal 0, material.sheen
    assert_equal 0x000000, material.sheen_color.hex
    assert_equal 1, material.sheen_roughness
    assert_equal 0, material.dispersion
    assert_equal 1, material.specular_intensity
    assert_equal 0xffffff, material.specular_color.hex
    assert_nil material.attenuation_distance
    assert_equal 0xffffff, material.attenuation_color.hex
    assert_empty material.textures
  end

  def test_accepts_physical_parameters_and_textures
    texture = Three::Texture.new("/texture.png")
    anisotropy_map = Three::Texture.new("/anisotropy.png")
    clearcoat_map = Three::Texture.new("/clearcoat.png")
    transmission_map = Three::Texture.new("/transmission.png")
    specular_color_map = Three::Texture.new("/specular-color.png")

    material = Three::MeshPhysicalMaterial.new(
      color: 0x99ccff,
      roughness: 0.35,
      metalness: 0.1,
      anisotropy: 0.4,
      anisotropy_rotation: 0.2,
      clearcoat: 0.8,
      clearcoat_roughness: 0.25,
      transmission: 0.45,
      thickness: 0.2,
      ior: 1.45,
      reflectivity: 0.35,
      iridescence: 0.2,
      iridescence_ior: 1.15,
      iridescence_thickness_range: [120, 360],
      sheen: 0.3,
      sheen_color: 0x223344,
      sheen_roughness: 0.65,
      dispersion: 0.1,
      specular_intensity: 0.7,
      specular_color: 0xf0f6ff,
      attenuation_distance: 5,
      attenuation_color: 0x88aaff,
      map: texture,
      anisotropy_map: anisotropy_map,
      clearcoat_map: clearcoat_map,
      transmission_map: transmission_map,
      specular_color_map: specular_color_map
    )

    assert_equal 0x99ccff, material.color.hex
    assert_equal 0.4, material.anisotropy
    assert_equal 0.2, material.anisotropy_rotation
    assert_equal 0.8, material.clearcoat
    assert_equal 0.25, material.clearcoat_roughness
    assert_equal 0.45, material.transmission
    assert_equal 0.2, material.thickness
    assert_in_delta 1.3255813953488373, material.ior
    assert_equal 0.35, material.reflectivity
    assert_equal 0.2, material.iridescence
    assert_equal 1.15, material.iridescence_ior
    assert_equal [120, 360], material.iridescence_thickness_range
    assert_equal 0.3, material.sheen
    assert_equal 0x223344, material.sheen_color.hex
    assert_equal 0.65, material.sheen_roughness
    assert_equal 0.1, material.dispersion
    assert_equal 0.7, material.specular_intensity
    assert_equal 0xf0f6ff, material.specular_color.hex
    assert_equal 5, material.attenuation_distance
    assert_equal 0x88aaff, material.attenuation_color.hex
    assert_equal [texture, anisotropy_map, clearcoat_map, transmission_map, specular_color_map], material.textures
  end

  def test_reflectivity_tracks_ior
    material = Three::MeshPhysicalMaterial.new(ior: 1.45)

    assert_in_delta 0.4591836734693877, material.reflectivity

    material.reflectivity = 0.35

    assert_in_delta 1.3255813953488373, material.ior
    assert_equal 0.35, material.reflectivity
  end

  def test_marks_dirty_when_physical_properties_change
    material = Three::MeshPhysicalMaterial.new
    material.mark_clean!

    material.clearcoat = 0.5
    material.specular_color.set_hex(0x112233)
    material.clearcoat_map = Three::Texture.new("/clearcoat.png")

    assert material.dirty_field?(:parameters)
  end

  def test_to_h
    material = Three::MeshPhysicalMaterial.new(
      color: 0x112233,
      anisotropy: 0.4,
      clearcoat: 0.8,
      anisotropy_map: Three::Texture.new("/anisotropy.png"),
      clearcoat_map: Three::Texture.new("/clearcoat.png"),
      transmission: 0.25,
      thickness: 0.1,
      dispersion: 0.05,
      specular_color: 0xf0f6ff,
      specular_intensity_map: Three::Texture.new("/specular-intensity.png")
    )

    assert_equal "MeshPhysicalMaterial", material.to_h[:type]
    assert_equal 0x112233, material.to_h[:color]
    assert_equal 0.4, material.to_h[:anisotropy]
    assert_equal "/anisotropy.png", material.to_h[:anisotropy_map][:source]
    assert_equal 0.8, material.to_h[:clearcoat]
    assert_equal "/clearcoat.png", material.to_h[:clearcoat_map][:source]
    assert_equal 0.25, material.to_h[:transmission]
    assert_equal 0.1, material.to_h[:thickness]
    assert_equal 0.05, material.to_h[:dispersion]
    assert_equal 0xf0f6ff, material.to_h[:specular_color]
    assert_equal "/specular-intensity.png", material.to_h[:specular_intensity_map][:source]
  end
end
