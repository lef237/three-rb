# frozen_string_literal: true

module Three
  module Backends
    class ThreeJS
      module Synchronization
        private

        def sync_object3d(object, handle)
          sync_scene(object, handle) if object.is_a?(Scene) && (object.dirty_field?(:scene) || scene_resource_dirty?(object))

          if object.dirty_field?(:properties)
            @adapter.set_object_name(handle, object.name)
            @adapter.set_object_visible(handle, object.visible)
            @adapter.set_object_shadow(handle, object.cast_shadow, object.receive_shadow)
          end

          if object.dirty_field?(:transform)
            @adapter.set_object_transform(handle, object.position.to_a, object.quaternion.to_a, object.scale.to_a)
          end

          if object.dirty_field?(:camera)
            sync_camera(object, handle)
          end

          sync_light(object, handle) if object.is_a?(Light) && object.dirty_field?(:light)

          if object.is_a?(InstancedMesh)
            sync_instanced_mesh(object, handle)
          elsif geometry_material_object?(object)
            sync_geometry_material_object(object, handle)
          end

          if object.dirty_field?(:children)
            @adapter.clear_children(handle)
            object.children.each do |child|
              child_handle = sync(child)
              @adapter.add_child(handle, child_handle)
            end
          elsif object.dirty_field?(:descendants)
            object.children.each { |child| sync(child) if child.dirty? }
          else
            # Clean subtrees do not need a Ruby-to-JavaScript sync pass.
          end

          object.mark_clean! if object.respond_to?(:mark_clean!)
          handle
        end

        def sync_instanced_mesh(object, handle)
          geometry_handle = sync(object.geometry)
          material_handle = sync(object.material) if object.material.respond_to?(:uuid)

          if object.dirty_field?(:mesh)
            @adapter.set_object_geometry(handle, geometry_handle)
            @adapter.set_object_material(handle, material_handle) if material_handle
            @adapter.set_instanced_mesh_count(handle, object.count)
          end

          if object.dirty_field?(:instances)
            object.instance_matrices.each_with_index do |matrix, index|
              @adapter.set_instanced_mesh_matrix_at(handle, index, matrix.to_a)
            end
            @adapter.set_instanced_mesh_instance_matrix_needs_update(handle, true)
          end

          sync_instanced_mesh_colors(object, handle) if object.dirty_field?(:instance_colors)
        end

        def geometry_material_object?(object)
          object.is_a?(Mesh) || object.is_a?(Line) || object.is_a?(Points)
        end

        def sync_geometry_material_object(object, handle)
          geometry_handle = sync(object.geometry)
          material_handle = sync(object.material) if object.material.respond_to?(:uuid)
          dirty_field = geometry_material_dirty_field(object)

          if object.dirty_field?(dirty_field)
            @adapter.set_object_geometry(handle, geometry_handle)
            @adapter.set_object_material(handle, material_handle) if material_handle
          end
        end

        def geometry_material_dirty_field(object)
          case object
          when Line
            :line
          when Points
            :points
          else
            :mesh
          end
        end

        def sync_instanced_mesh_colors(object, handle)
          return unless object.instance_colors

          object.instance_colors.each_with_index do |color, index|
            @adapter.set_instanced_mesh_color_at(handle, index, color.to_a)
          end
          @adapter.set_instanced_mesh_instance_color_needs_update(handle, true)
        end

        def sync_scene(scene, handle)
          @adapter.set_scene_background(handle, scene.background ? sync(scene.background) : nil)
          @adapter.set_scene_environment(handle, scene.environment ? sync(scene.environment) : nil)
        end

        def scene_resource_dirty?(scene)
          [scene.background, scene.environment].compact.any? do |resource|
            resource.respond_to?(:dirty?) && resource.dirty?
          end
        end

        def sync_camera(object, handle)
          case object
          when OrthographicCamera
            @adapter.update_orthographic_camera(handle, object.left, object.right, object.top, object.bottom, object.near, object.far, object.zoom)
          when PerspectiveCamera
            @adapter.update_perspective_camera(handle, object.fov, object.aspect, object.near, object.far, object.zoom)
          end
        end

        def sync_light(object, handle)
          case object
          when PointLight
            @adapter.update_point_light(handle, object.color.hex, object.intensity, object.distance, object.decay)
          when HemisphereLight
            @adapter.update_hemisphere_light(handle, object.color.hex, object.ground_color.hex, object.intensity)
          else
            @adapter.update_light(handle, object.color.hex, object.intensity)
          end
          @adapter.update_light_shadow(handle, light_shadow_parameters(object)) if shadow_dirty?(object)
        end

        def shadow_dirty?(object)
          object.dirty_fields.key?(:all) || object.dirty_field?(:shadow)
        end

        def sync_material(material, handle)
          sync_material_textures(material)
          return handle unless material.dirty?

          @adapter.update_material(handle, material_parameters(material))
          material.mark_clean!
          handle
        end

        def sync_material_textures(material)
          material_textures(material).each { |texture| sync(texture) }
        end

        def sync_texture(texture, handle)
          return handle unless texture.dirty?

          @adapter.update_texture(handle, texture_parameters(texture))
          texture.mark_clean!
          handle
        end

        def sync_geometry(geometry, handle)
          return handle if built_in_geometry?(geometry)
          return handle unless geometry_dirty?(geometry)

          if geometry.dirty_field?(:all) || geometry.dirty_field?(:index) || geometry.index&.dirty?
            @adapter.set_geometry_index(handle, geometry.index ? build_buffer_attribute(geometry.index) : nil)
            geometry.index&.mark_clean!
          end

          if geometry.dirty_field?(:all) || geometry.dirty_field?(:attributes) || geometry.attributes.values.any?(&:dirty?)
            previous_names = @geometry_attribute_names[geometry.uuid] || []
            current_names = geometry.attributes.keys
            (previous_names - current_names).each { |name| @adapter.delete_geometry_attribute(handle, name) }

            geometry.attributes.each do |name, attribute|
              @adapter.set_geometry_attribute(handle, name, build_buffer_attribute(attribute))
              attribute.mark_clean!
            end
            @geometry_attribute_names[geometry.uuid] = current_names
          end

          if geometry.dirty_field?(:all) || geometry.dirty_field?(:groups)
            @adapter.clear_geometry_groups(handle)
            geometry.groups.each do |group|
              @adapter.add_geometry_group(handle, group[:start], group[:count], group[:material_index])
            end
          end

          if geometry.dirty_field?(:all) || geometry.dirty_field?(:draw_range)
            @adapter.set_geometry_draw_range(handle, geometry.draw_range[:start], geometry.draw_range[:count])
          end

          geometry.mark_clean!
          handle
        end

        def geometry_dirty?(geometry)
          geometry.dirty? ||
            geometry.index&.dirty? ||
            geometry.attributes.values.any?(&:dirty?)
        end

        def built_in_geometry?(geometry)
          geometry.is_a?(BoxGeometry) || geometry.is_a?(PlaneGeometry) || geometry.is_a?(SphereGeometry)
        end
      end

      include Synchronization
    end
  end
end
