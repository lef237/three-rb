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
    material = Three::MeshBasicMaterial.new(color: 0x00ff00, wireframe: true, opacity: 0.25, transparent: true)

    assert_equal 0x00ff00, material.color.hex
    assert material.wireframe
    assert_equal 0.25, material.opacity
    assert material.transparent
  end
end
