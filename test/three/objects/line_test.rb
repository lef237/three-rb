# frozen_string_literal: true

require "test_helper"

class ThreeLineTest < Minitest::Test
  def test_defaults
    line = Three::Line.new

    assert_equal "Line", line.type
    assert_instance_of Three::BufferGeometry, line.geometry
    assert_instance_of Three::LineBasicMaterial, line.material
  end

  def test_accepts_geometry_and_material
    geometry = Three::BufferGeometry.new
    material = Three::LineBasicMaterial.new(color: 0xff0000)
    line = Three::Line.new(geometry, material)

    assert_same geometry, line.geometry
    assert_same material, line.material
  end

  def test_can_be_added_to_scene
    scene = Three::Scene.new
    line = Three::Line.new

    scene.add(line)

    assert_same scene, line.parent
    assert_equal [line], scene.children
  end
end
