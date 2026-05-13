# frozen_string_literal: true

require "test_helper"

class ThreePointsTest < Minitest::Test
  def test_defaults
    points = Three::Points.new

    assert_equal "Points", points.type
    assert_instance_of Three::BufferGeometry, points.geometry
    assert_instance_of Three::PointsMaterial, points.material
  end

  def test_accepts_geometry_and_material
    geometry = Three::BufferGeometry.new
    material = Three::PointsMaterial.new(color: 0x00ff00, size: 2)
    points = Three::Points.new(geometry, material)

    assert_same geometry, points.geometry
    assert_same material, points.material
  end

  def test_can_be_added_to_scene
    scene = Three::Scene.new
    points = Three::Points.new

    scene.add(points)

    assert_same scene, points.parent
    assert_equal [points], scene.children
  end
end
