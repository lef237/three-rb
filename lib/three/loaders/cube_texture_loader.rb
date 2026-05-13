# frozen_string_literal: true

require_relative "../textures/cube_texture"

module Three
  module Loaders
    class CubeTextureLoader
      def load(sources)
        CubeTexture.new(sources)
      end
    end
  end
end
