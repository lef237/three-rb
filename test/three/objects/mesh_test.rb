# frozen_string_literal: true

require "test_helper"

class ThreeMeshTest < Minitest::Test
  def test_defaults
    mesh = Three::Mesh.new

    assert_equal "Mesh", mesh.type
    assert_instance_of Three::BufferGeometry, mesh.geometry
    assert_instance_of Three::MeshBasicMaterial, mesh.material
  end

  def test_accepts_geometry_and_material
    geometry = Three::BoxGeometry.new
    material = Three::MeshBasicMaterial.new(color: 0xff0000)
    mesh = Three::Mesh.new(geometry, material)

    assert_same geometry, mesh.geometry
    assert_same material, mesh.material
  end

  def test_can_be_added_to_scene
    scene = Three::Scene.new
    mesh = Three::Mesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new)

    scene.add(mesh)

    assert_same scene, mesh.parent
    assert_equal [mesh], scene.children
  end
end
