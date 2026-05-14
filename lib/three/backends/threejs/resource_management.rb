# frozen_string_literal: true

module Three
  module Backends
    class ThreeJS
      module ResourceManagement
        private

        def dispose_material_textures(material)
          material_textures(material).each { |texture| dispose(texture) }
        end

        def release_cached_subtree_handles(object, dispose_geometries:, dispose_materials:, dispose_textures:)
          if object.respond_to?(:traverse)
            object.traverse do |node|
              release_cached_object_handles(
                node,
                dispose_geometries: dispose_geometries,
                dispose_materials: dispose_materials,
                dispose_textures: dispose_textures
              )
            end
          else
            key = cache_key(object)
            @handles.delete(key) if key
          end
        end

        def release_cached_object_handles(object, dispose_geometries:, dispose_materials:, dispose_textures:)
          key = cache_key(object)
          handle = key ? @handles.delete(key) : nil
          handle_key = @adapter.object_handle_key(handle) if handle
          @objects_by_handle_key.delete(handle_key) if handle_key

          if object.respond_to?(:geometry) && object.respond_to?(:material)
            release_cached_resource(object.geometry) if dispose_geometries
          end

          if object.respond_to?(:material)
            release_cached_material(object.material, dispose_textures: dispose_textures) if dispose_materials
          end

          return unless object.is_a?(Scene) && dispose_textures

          release_cached_resource(object.background)
          release_cached_resource(object.environment)
        end

        def release_cached_material(material, dispose_textures:)
          release_cached_resource(material)
          material_textures(material).each { |texture| release_cached_resource(texture) } if dispose_textures
        end

        def release_cached_resource(resource)
          key = cache_key(resource)
          @handles.delete(key) if key
        end

        def material_textures(material)
          return material.textures if material.respond_to?(:textures)

          []
        end
      end

      include ResourceManagement
    end
  end
end
