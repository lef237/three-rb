# frozen_string_literal: true

require_relative "../backends/threejs"

module Three
  module Postprocessing
    class EffectComposer
      attr_reader :renderer, :backend, :handle, :passes

      def initialize(renderer:, backend: nil)
        @renderer = renderer
        renderer_backend = renderer.backend if renderer.respond_to?(:backend)
        @backend = backend || renderer_backend
        raise ArgumentError, "renderer must expose a backend or backend must be provided" unless @backend
        if renderer_backend && !renderer_backend.equal?(@backend)
          raise ArgumentError, "effect composer backend must match the renderer backend"
        end

        @handle = @backend.create_effect_composer(renderer.handle)
        @passes = []
      end

      def add_pass(pass)
        ensure_pass_backend!(pass)
        @passes << pass
        @backend.add_effect_composer_pass(@handle, pass.handle)
        self
      end

      def set_size(width, height)
        @backend.set_effect_composer_size(@handle, width, height)
        self
      end

      def render(scene = nil, camera = nil)
        scene.update_matrix_world if scene.respond_to?(:update_matrix_world)
        camera.update_matrix_world if camera.respond_to?(:update_matrix_world) && camera.parent.nil?
        @backend.render_effect_composer(@handle, scene, camera)
        self
      end

      def dispose
        @backend.dispose_effect_composer(@handle)
        self
      end

      private

      def ensure_pass_backend!(pass)
        return if pass.respond_to?(:backend) && pass.backend.equal?(@backend)

        raise ArgumentError, "postprocessing pass must use the same backend as the composer"
      end
    end
  end
end
