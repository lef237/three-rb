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

  def test_update_matrix_world_does_not_mark_clean_object_dirty
    object = Three::Object3D.new
    object.update_matrix_world
    object.mark_clean!

    object.update_matrix_world

    refute object.dirty?
  end

  def test_rotation_and_quaternion_stay_in_sync
    object = Three::Object3D.new

    object.rotation.x = Math::PI / 2

    assert_in_delta Math.sqrt(0.5), object.quaternion.x, 1e-12
    assert_in_delta Math.sqrt(0.5), object.quaternion.w, 1e-12

    object.quaternion.set_from_axis_angle(Three::Vector3.new(0, 1, 0), Math::PI / 2)

    assert_in_delta Math::PI / 2, object.rotation.y, 1e-12
  end

  def test_marks_transform_dirty_when_position_changes
    object = Three::Object3D.new
    object.mark_clean!

    object.position.set(1, 2, 3)

    assert object.dirty_field?(:transform)
  end

  def test_marks_ancestors_dirty_when_descendant_changes
    root = Three::Object3D.new
    child = Three::Object3D.new
    root.add(child)
    root.mark_clean!
    child.mark_clean!

    child.position.set(1, 2, 3)

    assert child.dirty_field?(:transform)
    assert root.dirty_field?(:descendants)
  end

  def test_marks_children_dirty_when_child_is_added
    parent = Three::Object3D.new
    parent.mark_clean!

    parent.add(Three::Object3D.new)

    assert parent.dirty_field?(:children)
  end

  def test_shadow_flags_mark_properties_dirty
    object = Three::Object3D.new
    object.mark_clean!

    object.cast_shadow = true
    object.receive_shadow = true

    assert object.cast_shadow
    assert object.receive_shadow
    assert object.dirty_field?(:properties)
    assert_equal true, object.to_h[:cast_shadow]
    assert_equal true, object.to_h[:receive_shadow]
  end
end
