# frozen_string_literal: true

require "test_helper"

class ThreeColorTest < Minitest::Test
  def test_defaults_to_white
    assert_equal 0xffffff, Three::Color.new.hex
  end

  def test_sets_from_hex_integer
    color = Three::Color.new(0xff8000)

    assert_in_delta 1.0, color.r, 1e-12
    assert_in_delta 128 / 255.0, color.g, 1e-12
    assert_in_delta 0.0, color.b, 1e-12
  end

  def test_sets_from_css_hex
    assert_equal 0x336699, Three::Color.new("#336699").hex
  end

  def test_copy
    source = Three::Color.new(0x123456)
    target = Three::Color.new

    target.copy(source)

    assert_equal source, target
  end
end
