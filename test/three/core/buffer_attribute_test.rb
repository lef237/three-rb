# frozen_string_literal: true

require "test_helper"

class ThreeBufferAttributeTest < Minitest::Test
  def test_count
    attribute = Three::BufferAttribute.new([1, 2, 3, 4, 5, 6], 3)

    assert_equal 2, attribute.count
  end

  def test_component_access
    attribute = Three::BufferAttribute.new([1, 2, 3, 4, 5, 6], 3)

    assert_equal 4, attribute.get_x(1)
    assert_same attribute, attribute.set_z(1, 9)
    assert_equal [1, 2, 3, 4, 5, 9], attribute.array
  end

  def test_needs_update_increments_version
    attribute = Three::BufferAttribute.new([1, 2, 3], 3)

    attribute.needs_update = true

    assert_equal 1, attribute.version
  end

  def test_update_ranges
    attribute = Three::BufferAttribute.new([1, 2, 3], 3)

    attribute.add_update_range(0, 3)
    assert_equal [{ start: 0, count: 3 }], attribute.update_ranges

    attribute.clear_update_ranges
    assert_empty attribute.update_ranges
  end

  def test_typed_attribute_component_type
    assert_equal :float32, Three::Float32BufferAttribute.new([1, 2, 3], 3).component_type
    assert_equal :uint16, Three::Uint16BufferAttribute.new([1, 2, 3], 1).component_type
    assert_equal :uint32, Three::Uint32BufferAttribute.new([70_000], 1).component_type
  end

  def test_clone_preserves_generic_component_type
    attribute = Three::BufferAttribute.new([1, 2, 3], 1, false, component_type: :int16)

    clone = attribute.clone

    assert_instance_of Three::BufferAttribute, clone
    assert_equal :int16, clone.component_type
    assert_equal [1, 2, 3], clone.array
  end
end
