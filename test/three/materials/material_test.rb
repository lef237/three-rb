# frozen_string_literal: true

require "test_helper"

class ThreeMaterialTest < Minitest::Test
  def test_defaults
    material = Three::Material.new

    assert_equal "Material", material.type
    assert_equal Three::FrontSide, material.side
    assert_equal 1, material.opacity
    refute material.transparent
  end

  def test_sets_values_for_known_properties
    material = Three::Material.new(opacity: 0.5, transparent: true, vertex_colors: true)

    assert_equal 0.5, material.opacity
    assert material.transparent
    assert material.vertex_colors
    assert_equal true, material.to_h[:vertex_colors]
  end

  def test_dispose_event
    material = Three::Material.new
    called = false
    material.on(:dispose) { called = true }

    material.dispose

    assert called
  end
end
