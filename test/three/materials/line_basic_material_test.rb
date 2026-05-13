# frozen_string_literal: true

require "test_helper"

class ThreeLineBasicMaterialTest < Minitest::Test
  def test_defaults
    material = Three::LineBasicMaterial.new

    assert_equal "LineBasicMaterial", material.type
    assert_equal 0xffffff, material.color.hex
    assert_equal 1, material.linewidth
    assert_equal "round", material.linecap
    assert_equal "round", material.linejoin
    assert material.fog
  end

  def test_accepts_parameters
    material = Three::LineBasicMaterial.new(color: 0xff8844, linewidth: 2, linecap: "butt", linejoin: "miter", fog: false)

    assert_equal 0xff8844, material.color.hex
    assert_equal 2, material.linewidth
    assert_equal "butt", material.linecap
    assert_equal "miter", material.linejoin
    refute material.fog
  end

  def test_marks_dirty_when_color_changes
    material = Three::LineBasicMaterial.new(color: 0xff0000)
    material.mark_clean!

    material.color.set_hex(0x00ff00)

    assert material.dirty_field?(:parameters)
  end
end
