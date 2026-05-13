# frozen_string_literal: true

require "test_helper"

class ThreeVector2Test < Minitest::Test
  def test_initializes_to_zero_by_default
    assert_equal [0, 0], Three::Vector2.new.to_a
  end

  def test_set_mutates_and_returns_self
    vector = Three::Vector2.new

    assert_same vector, vector.set(1, 2)
    assert_equal [1, 2], vector.to_a
  end

  def test_clone_returns_distinct_vector
    vector = Three::Vector2.new(1, 2)
    clone = vector.clone

    assert_equal vector, clone
    refute_same vector, clone
  end

  def test_copy_reads_components
    source = Three::Vector2.new(4, 5)
    target = Three::Vector2.new

    assert_same target, target.copy(source)
    assert_equal [4, 5], target.to_a
  end

  def test_array_helpers
    vector = Three::Vector2.new.from_array([nil, 3, 4], 1)

    assert_equal [3, 4], vector.to_a
    assert_equal [nil, 3, 4], vector.to_array([nil], 1)
  end

  def test_on_change_callback
    calls = 0
    vector = Three::Vector2.new
    vector.on_change { calls += 1 }

    vector.set(1, 2)

    assert_equal 1, calls
  end
end
