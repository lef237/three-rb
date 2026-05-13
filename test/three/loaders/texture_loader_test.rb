# frozen_string_literal: true

require "test_helper"

class ThreeTextureLoaderTest < Minitest::Test
  def test_load_returns_texture_with_source
    texture = Three::Loaders::TextureLoader.new.load("/texture.png")

    assert_instance_of Three::Texture, texture
    assert_equal "/texture.png", texture.source
  end
end
