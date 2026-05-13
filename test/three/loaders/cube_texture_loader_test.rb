# frozen_string_literal: true

require "test_helper"

class ThreeCubeTextureLoaderTest < Minitest::Test
  def test_load_returns_cube_texture_with_sources
    sources = %w[
      /px.png
      /nx.png
      /py.png
      /ny.png
      /pz.png
      /nz.png
    ]

    texture = Three::Loaders::CubeTextureLoader.new.load(sources)

    assert_instance_of Three::CubeTexture, texture
    assert_equal sources, texture.sources
  end
end
