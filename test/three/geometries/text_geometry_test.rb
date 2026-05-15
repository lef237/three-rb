# frozen_string_literal: true

require "test_helper"

class ThreeTextGeometryTest < Minitest::Test
  def test_stores_text_and_extrusion_parameters
    font = Three::Font.new({ type: :font })
    geometry = Three::TextGeometry.new(
      "three-rb",
      font: font,
      size: 0.5,
      depth: 0.12,
      curve_segments: 10,
      steps: 2,
      bevel_enabled: true,
      bevel_thickness: 0.02,
      bevel_size: 0.015,
      bevel_offset: 0.001,
      bevel_segments: 4,
      direction: "ltr"
    )

    assert_equal "TextGeometry", geometry.type
    assert_equal "three-rb", geometry.text
    assert_same font, geometry.parameters[:font]
    assert_equal 0.5, geometry.parameters[:size]
    assert_equal 0.12, geometry.parameters[:depth]
    assert_equal 10, geometry.parameters[:curve_segments]
    assert_equal 2, geometry.parameters[:steps]
    assert_equal true, geometry.parameters[:bevel_enabled]
    assert_equal 0.02, geometry.parameters[:bevel_thickness]
    assert_equal 0.015, geometry.parameters[:bevel_size]
    assert_equal 0.001, geometry.parameters[:bevel_offset]
    assert_equal 4, geometry.parameters[:bevel_segments]
    assert_equal "ltr", geometry.parameters[:direction]
  end
end
