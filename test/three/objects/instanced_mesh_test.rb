# frozen_string_literal: true

require "test_helper"

class ThreeInstancedMeshTest < Minitest::Test
  def test_defaults
    mesh = Three::InstancedMesh.new

    assert_equal "InstancedMesh", mesh.type
    assert_equal 1, mesh.count
    assert_equal 1, mesh.capacity
    assert_equal 1, mesh.instance_matrices.length
    assert_instance_of Three::BufferGeometry, mesh.geometry
    assert_instance_of Three::MeshBasicMaterial, mesh.material
  end

  def test_accepts_geometry_material_and_count
    geometry = Three::BoxGeometry.new
    material = Three::MeshBasicMaterial.new(color: 0xff0000)
    mesh = Three::InstancedMesh.new(geometry, material, 3)

    assert_same geometry, mesh.geometry
    assert_same material, mesh.material
    assert_equal 3, mesh.count
    assert_equal 3, mesh.capacity
    assert_equal 3, mesh.instance_matrices.length
  end

  def test_set_and_get_matrix_at
    mesh = Three::InstancedMesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new, 2)
    matrix = Three::Matrix4.new.make_translation(1, 2, 3)

    mesh.mark_clean!
    mesh.set_matrix_at(1, matrix)
    result = mesh.get_matrix_at(1)

    assert_equal matrix, result
    refute_same matrix, result
    assert mesh.dirty_field?(:instances)
  end

  def test_count_sets_rendered_instance_count_within_capacity
    mesh = Three::InstancedMesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new, 3)
    matrix = Three::Matrix4.new.make_translation(4, 5, 6)

    mesh.set_matrix_at(0, matrix)
    mesh.mark_clean!
    mesh.count = 2

    assert_equal 2, mesh.count
    assert_equal 3, mesh.capacity
    assert_equal 3, mesh.instance_matrices.length
    assert_equal matrix, mesh.get_matrix_at(0)
    assert_equal Three::Matrix4.new, mesh.get_matrix_at(2)
    assert mesh.dirty_field?(:mesh)
    refute mesh.dirty_field?(:instances)
  end

  def test_rejects_invalid_count_and_index
    assert_raises(ArgumentError) { Three::InstancedMesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new, -1) }

    mesh = Three::InstancedMesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new, 1)

    assert_raises(ArgumentError) { mesh.count = 2 }
    assert_raises(IndexError) { mesh.set_matrix_at(1, Three::Matrix4.new) }
    assert_raises(IndexError) { mesh.get_matrix_at(-1) }
  end
end
