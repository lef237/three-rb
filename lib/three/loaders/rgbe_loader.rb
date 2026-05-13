# frozen_string_literal: true

require_relative "../textures/rgbe_texture"

module Three
  module Loaders
    class RGBELoader
      def load(source, **parameters)
        texture = RGBETexture.new(source, **parameters)
        yield texture if block_given?
        texture
      end
    end
  end
end
