# frozen_string_literal: true

require_relative "../textures/texture"

module Three
  module Loaders
    class TextureLoader
      def load(source)
        Texture.new(source)
      end
    end
  end
end
