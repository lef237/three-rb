# frozen_string_literal: true

require "test_helper"

class ThreeFontLoaderTest < Minitest::Test
  def test_loads_font_with_adapter
    adapter = FakeThreeJSAdapter.new
    loader = Three::Loaders::FontLoader.new(adapter: adapter)

    font = loader.load("/fonts/helvetiker_bold.typeface.json")

    assert_instance_of Three::Font, font
    assert_equal :font, font.handle[:type]
    assert_equal "/fonts/helvetiker_bold.typeface.json", font.handle[:source]
  end

  def test_yields_loaded_font
    adapter = FakeThreeJSAdapter.new
    loader = Three::Loaders::FontLoader.new(adapter: adapter)
    yielded = nil

    font = loader.load("/fonts/helvetiker_regular.typeface.json") { |value| yielded = value }

    assert_same font, yielded
  end
end
