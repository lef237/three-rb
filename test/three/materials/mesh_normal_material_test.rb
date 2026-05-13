# frozen_string_literal: true

require "test_helper"

class ThreeMeshNormalMaterialTest < Minitest::Test
  def test_defaults
    material = Three::MeshNormalMaterial.new

    assert_equal "MeshNormalMaterial", material.type
    refute material.wireframe
    refute material.flat_shading
    assert_equal 1, material.wireframe_linewidth
  end

  def test_accepts_parameters
    material = Three::MeshNormalMaterial.new(wireframe: true, flat_shading: true, opacity: 0.5, transparent: true)

    assert material.wireframe
    assert material.flat_shading
    assert_equal 0.5, material.opacity
    assert material.transparent
  end

  def test_marks_dirty_when_flat_shading_changes
    material = Three::MeshNormalMaterial.new
    material.mark_clean!

    material.flat_shading = true

    assert material.dirty_field?(:parameters)
  end

  def test_to_h
    material = Three::MeshNormalMaterial.new(wireframe: true, flat_shading: true)

    assert_equal "MeshNormalMaterial", material.to_h[:type]
    assert material.to_h[:wireframe]
    assert material.to_h[:flat_shading]
  end
end
