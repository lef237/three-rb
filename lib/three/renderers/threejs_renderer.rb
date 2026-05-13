# frozen_string_literal: true

require_relative "../backends/threejs"
require_relative "renderer"

module Three
  module Renderers
    class ThreeJSRenderer < Renderer
      attr_reader :backend, :handle

      def initialize(canvas: nil, backend: Backends::ThreeJS.new, **options)
        @backend = backend
        @handle = @backend.create_renderer(canvas: canvas, **options)
      end

      def set_size(width, height)
        @backend.set_renderer_size(@handle, width, height)
        self
      end

      def dom_element
        @backend.renderer_dom_element(@handle)
      end

      def set_clear_color(color, alpha = 1)
        @backend.set_clear_color(@handle, color, alpha)
        self
      end

      def animation_loop(&block)
        @backend.set_animation_loop(@handle, block)
        self
      end

      def render(scene, camera)
        scene.update_matrix_world if scene.respond_to?(:update_matrix_world)
        camera.update_matrix_world if camera.respond_to?(:update_matrix_world) && camera.parent.nil?
        @backend.render(@handle, scene, camera)
        self
      end

      def dispose(object, **options)
        @backend.dispose(object, **options)
        self
      end

      def traverse_handles(object, &block)
        return enum_for(:traverse_handles, object) unless block

        @backend.traverse_handles(object, &block)
        self
      end

      def dispose_subtree(
        object,
        remove: true,
        dispose_geometries: true,
        dispose_materials: true,
        dispose_textures: true,
        dispose_skeletons: true
      )
        @backend.dispose_subtree(
          object,
          remove: remove,
          dispose_geometries: dispose_geometries,
          dispose_materials: dispose_materials,
          dispose_textures: dispose_textures,
          dispose_skeletons: dispose_skeletons
        )
        self
      end
    end
  end
end
