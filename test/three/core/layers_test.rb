# frozen_string_literal: true

require "test_helper"

class ThreeLayersTest < Minitest::Test
  def test_defaults_to_layer_zero
    layers = Three::Layers.new

    assert_equal 1, layers.mask
    assert layers.is_enabled(0)
    refute layers.is_enabled(1)
  end

  def test_enables_toggles_and_disables_layers
    layers = Three::Layers.new

    layers.enable(2)
    assert_equal 0b101, layers.mask
    assert layers.is_enabled(2)

    layers.toggle(2)
    refute layers.is_enabled(2)

    layers.disable(0)
    assert_equal 0, layers.mask
  end

  def test_set_enable_all_disable_all_and_test
    first = Three::Layers.new
    second = Three::Layers.new

    first.set(3)
    second.set(4)
    refute first.test(second)

    second.enable(3)
    assert first.test(second)

    first.enable_all
    assert_equal Three::Layers::ALL_MASK, first.mask
    first.disable_all
    assert_equal 0, first.mask
  end

  def test_calls_on_change_when_mask_changes
    layers = Three::Layers.new
    called = false
    layers.on_change { called = true }

    layers.enable(1)

    assert called
  end

  def test_rejects_invalid_layer_channel
    layers = Three::Layers.new

    assert_raises(RangeError) { layers.enable(32) }
  end
end
