# frozen_string_literal: true

module Three
  module Backends
    class ThreeJS
      module Materialization
        private

        def build_handle(object)
          case object
          when OrthographicCamera
            @adapter.new_orthographic_camera(object.left, object.right, object.top, object.bottom, object.near, object.far)
          when PerspectiveCamera
            @adapter.new_perspective_camera(object.fov, object.aspect, object.near, object.far)
          when Scene
            @adapter.new_scene
          when InstancedMesh
            @adapter.new_instanced_mesh(materialize(object.geometry), materialize(object.material), object.count)
          when Line
            @adapter.new_line(materialize(object.geometry), materialize(object.material))
          when Mesh
            @adapter.new_mesh(materialize(object.geometry), materialize(object.material))
          when Points
            @adapter.new_points(materialize(object.geometry), materialize(object.material))
          when Sprite
            @adapter.new_sprite(materialize(object.material))
          when CubeTexture
            @adapter.load_cube_texture(object.sources, texture_parameters(object))
          when RGBETexture
            @adapter.load_rgbe_texture(object.source, texture_parameters(object))
          when Texture
            @adapter.load_texture(object.source, texture_parameters(object))
          when AmbientLight
            @adapter.new_ambient_light(object.color.hex, object.intensity)
          when DirectionalLight
            @adapter.new_directional_light(object.color.hex, object.intensity)
          when PointLight
            @adapter.new_point_light(object.color.hex, object.intensity, object.distance, object.decay)
          when HemisphereLight
            @adapter.new_hemisphere_light(object.color.hex, object.ground_color.hex, object.intensity)
          when BoxGeometry
            parameters = object.parameters
            @adapter.new_box_geometry(
              parameters[:width],
              parameters[:height],
              parameters[:depth],
              parameters[:width_segments],
              parameters[:height_segments],
              parameters[:depth_segments]
            )
          when PlaneGeometry
            parameters = object.parameters
            @adapter.new_plane_geometry(
              parameters[:width],
              parameters[:height],
              parameters[:width_segments],
              parameters[:height_segments]
            )
          when SphereGeometry
            parameters = object.parameters
            @adapter.new_sphere_geometry(
              parameters[:radius],
              parameters[:width_segments],
              parameters[:height_segments],
              parameters[:phi_start],
              parameters[:phi_length],
              parameters[:theta_start],
              parameters[:theta_length]
            )
          when BufferGeometry
            build_buffer_geometry(object)
          when LineBasicMaterial
            @adapter.new_line_basic_material(material_parameters(object))
          when MeshBasicMaterial
            @adapter.new_mesh_basic_material(material_parameters(object))
          when MeshLambertMaterial
            @adapter.new_mesh_lambert_material(material_parameters(object))
          when MeshMatcapMaterial
            @adapter.new_mesh_matcap_material(material_parameters(object))
          when MeshNormalMaterial
            @adapter.new_mesh_normal_material(material_parameters(object))
          when MeshPhongMaterial
            @adapter.new_mesh_phong_material(material_parameters(object))
          when MeshPhysicalMaterial
            @adapter.new_mesh_physical_material(material_parameters(object))
          when MeshStandardMaterial
            @adapter.new_mesh_standard_material(material_parameters(object))
          when MeshToonMaterial
            @adapter.new_mesh_toon_material(material_parameters(object))
          when PointsMaterial
            @adapter.new_points_material(material_parameters(object))
          when ShadowMaterial
            @adapter.new_shadow_material(material_parameters(object))
          when SpriteMaterial
            @adapter.new_sprite_material(material_parameters(object))
          when Group
            @adapter.new_group
          when ExternalObject3D
            object.handle
          when Object3D
            @adapter.new_object3d
          else
            raise TypeError, "unsupported ThreeJS backend object: #{object.class}"
          end
        end

        def build_buffer_geometry(geometry)
          handle = @adapter.new_buffer_geometry

          @adapter.set_geometry_index(handle, build_buffer_attribute(geometry.index)) if geometry.index
          geometry.attributes.each do |name, attribute|
            @adapter.set_geometry_attribute(handle, name, build_buffer_attribute(attribute))
          end
          geometry.groups.each do |group|
            @adapter.add_geometry_group(handle, group[:start], group[:count], group[:material_index])
          end
          @adapter.set_geometry_draw_range(handle, geometry.draw_range[:start], geometry.draw_range[:count])
          handle
        end

        def build_buffer_attribute(attribute)
          @adapter.new_buffer_attribute(attribute.component_type, attribute.array, attribute.item_size, attribute.normalized)
        end

        def mark_clean_after_materialize(object)
          case object
          when Material
            object.mark_clean!
          when Texture
            object.mark_clean!
          when BufferGeometry
            @geometry_attribute_names[object.uuid] = object.attributes.keys
            object.mark_clean!
            object.index&.mark_clean!
            object.attributes.each_value(&:mark_clean!)
          end
        end
      end

      include Materialization
    end
  end
end
