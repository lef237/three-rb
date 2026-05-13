# frozen_string_literal: true

require "test_helper"

class ThreeRGBELoaderTest < Minitest::Test
  def test_load_returns_rgbe_texture_with_source
    texture = Three::Loaders::RGBELoader.new.load("/studio.hdr")

    assert_instance_of Three::RGBETexture, texture
    assert_equal "/studio.hdr", texture.source
    assert_equal Three::EquirectangularReflectionMapping, texture.mapping
  end

  def test_load_yields_texture
    yielded = nil

    texture = Three::Loaders::RGBELoader.new.load("/studio.hdr") { |loaded| yielded = loaded }

    assert_same texture, yielded
  end
end
