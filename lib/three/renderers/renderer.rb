# frozen_string_literal: true

module Three
  module Renderers
    class Renderer
      def render(_scene, _camera)
        raise NotImplementedError
      end
    end
  end
end
