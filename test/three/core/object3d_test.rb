# frozen_string_literal: true

require "test_helper"

class ThreeObject3DTest < Minitest::Test
  def test_add_sets_parent_and_dispatches_events
    parent = Three::Object3D.new
    child = Three::Object3D.new
    events = []

    child.on(:added) { |event| events << event.type }
    parent.on(:childadded) { |event| events << [event.type, event.data] }

    assert_same parent, parent.add(child)

    assert_same parent, child.parent
    assert_equal [child], parent.children
    assert_equal [:added, [:childadded, child]], events
  end

  def test_add_reparents_existing_child
    first = Three::Object3D.new
    second = Three::Object3D.new
    child = Three::Object3D.new

    first.add(child)
    second.add(child)

    assert_empty first.children
    assert_equal [child], second.children
    assert_same second, child.parent
  end

  def test_remove_clears_parent
    parent = Three::Object3D.new
    child = Three::Object3D.new

    parent.add(child)
    parent.remove(child)

    assert_nil child.parent
    assert_empty parent.children
  end

  def test_traverse_visits_depth_first
    root = Three::Object3D.new
    child = Three::Object3D.new
    grandchild = Three::Object3D.new
    root.name = "root"
    child.name = "child"
    grandchild.name = "grandchild"

    root.add(child)
    child.add(grandchild)

    assert_equal %w[root child grandchild], root.traverse.map(&:name)
  end

  def test_traverse_visible_skips_invisible_subtree
    root = Three::Object3D.new
    child = Three::Object3D.new
    grandchild = Three::Object3D.new
    child.visible = false

    root.add(child)
    child.add(grandchild)

    assert_equal [root], root.traverse_visible.to_a
  end

  def test_get_object_by_name
    root = Three::Object3D.new
    child = Three::Object3D.new
    child.name = "target"

    root.add(child)

    assert_same child, root.get_object_by_name("target")
  end

  def test_update_matrix_world_combines_parent_and_child_transform
    parent = Three::Object3D.new
    child = Three::Object3D.new
    parent.position.set(1, 2, 3)
    child.position.set(4, 5, 6)
    parent.add(child)

    parent.update_matrix_world

    assert_vector3_in_delta [5, 7, 9], child.get_world_position
  end

  def test_rotation_and_quaternion_stay_in_sync
    object = Three::Object3D.new

    object.rotation.x = Math::PI / 2

    assert_in_delta Math.sqrt(0.5), object.quaternion.x, 1e-12
    assert_in_delta Math.sqrt(0.5), object.quaternion.w, 1e-12

    object.quaternion.set_from_axis_angle(Three::Vector3.new(0, 1, 0), Math::PI / 2)

    assert_in_delta Math::PI / 2, object.rotation.y, 1e-12
  end
end
