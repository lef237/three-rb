# frozen_string_literal: true

require "json"

module Three
  module Exporters
    class ThreeJSONExporter
      FORMAT_VERSION = 1

      def initialize(deterministic_ids: false)
        @deterministic_ids = deterministic_ids
      end

      def export(object)
        raise TypeError, "object must be a Three::Object3D" unless object.is_a?(Object3D)

        reset!
        {
          metadata: {
            version: FORMAT_VERSION,
            generator: "three.rb",
            type: "Object"
          },
          object: serialize_object(object),
          geometries: @geometries.values,
          materials: @materials.values,
          textures: @textures.values
        }
      end

      def to_json(object, *args)
        export(object).to_json(*args)
      end

      private

      def reset!
        @geometries = {}
        @materials = {}
        @textures = {}
        @stable_ids = {}
        @stable_id_counts = Hash.new(0)
      end

      def serialize_object(object)
        data = {
          uuid: export_id(object, :object),
          type: object.type,
          name: object.name,
          visible: object.visible,
          layers: object.layers.mask,
          cast_shadow: object.cast_shadow,
          receive_shadow: object.receive_shadow,
          matrix_auto_update: object.matrix_auto_update,
          position: object.position.to_a,
          quaternion: object.quaternion.to_a,
          scale: object.scale.to_a,
          user_data: object.user_data,
          children: object.children.map { |child| serialize_object(child) }
        }

        serialize_scene(object, data) if object.is_a?(Scene)
        serialize_camera(object, data) if object.is_a?(Camera)
        serialize_light(object, data) if object.is_a?(Light)
        serialize_geometry_material_object(object, data) if geometry_material_object?(object)
        data[:external] = true if object.is_a?(ExternalObject3D)

        data
      end

      def serialize_scene(scene, data)
        data[:background] = serialize_texture_reference(scene.background)
        data[:environment] = serialize_texture_reference(scene.environment)
      end

      def serialize_camera(camera, data)
        data[:zoom] = camera.zoom if camera.respond_to?(:zoom)

        case camera
        when PerspectiveCamera
          data[:fov] = camera.fov
          data[:aspect] = camera.aspect
          data[:near] = camera.near
          data[:far] = camera.far
        when OrthographicCamera
          data[:left] = camera.left
          data[:right] = camera.right
          data[:top] = camera.top
          data[:bottom] = camera.bottom
          data[:near] = camera.near
          data[:far] = camera.far
        end
      end

      def serialize_light(light, data)
        data[:color] = light.color.hex
        data[:intensity] = light.intensity
        data[:shadow_map_size] = light.shadow_map_size.dup
        data[:shadow_bias] = light.shadow_bias
        data[:shadow_normal_bias] = light.shadow_normal_bias
        data[:shadow_radius] = light.shadow_radius
        data[:shadow_camera] = light.shadow_camera.dup if light.respond_to?(:shadow_camera)
        data[:distance] = light.distance if light.respond_to?(:distance)
        data[:decay] = light.decay if light.respond_to?(:decay)
        data[:ground_color] = light.ground_color.hex if light.respond_to?(:ground_color)
      end

      def geometry_material_object?(object)
        object.is_a?(Mesh) || object.is_a?(Line) || object.is_a?(Points)
      end

      def serialize_geometry_material_object(object, data)
        data[:geometry] = register_geometry(object.geometry)
        data[:material] = register_material(object.material)

        return unless object.is_a?(InstancedMesh)

        data[:count] = object.count
        data[:capacity] = object.capacity
        data[:instance_matrices] = object.instance_matrices.map(&:to_a)
        data[:instance_colors] = object.instance_colors&.map(&:to_a)
      end

      def register_geometry(geometry)
        return nil unless geometry&.respond_to?(:uuid)

        @geometries[geometry.uuid] ||= serialize_geometry(geometry)
        export_id(geometry, :geometry)
      end

      def serialize_geometry(geometry)
        data = geometry.to_h
        data[:uuid] = export_id(geometry, :geometry)
        data[:parameters] = geometry.parameters.dup if geometry.respond_to?(:parameters)
        data
      end

      def register_material(material)
        return material.map { |entry| register_material(entry) } if material.is_a?(Array)
        return nil unless material&.respond_to?(:uuid)

        @materials[material.uuid] ||= serialize_material(material)
        export_id(material, :material)
      end

      def serialize_material(material)
        data = material.to_h
        data[:uuid] = export_id(material, :material)
        material.textures.each { |texture| register_texture(texture) } if material.respond_to?(:textures)

        return data unless material.respond_to?(:texture_slots)

        material.texture_slots.each do |slot|
          data[slot] = serialize_texture_reference(material.public_send(slot))
        end
        data
      end

      def serialize_texture_reference(texture)
        return nil unless texture
        return texture unless texture.respond_to?(:uuid)

        register_texture(texture)
      end

      def register_texture(texture)
        @textures[texture.uuid] ||= serialize_texture(texture)
        export_id(texture, :texture)
      end

      def serialize_texture(texture)
        texture.to_h.merge(uuid: export_id(texture, :texture))
      end

      def export_id(resource, prefix)
        return resource.uuid unless @deterministic_ids

        @stable_ids[resource.uuid] ||= begin
          index = @stable_id_counts[prefix]
          @stable_id_counts[prefix] += 1
          "#{prefix}-#{index}"
        end
      end
    end
  end
end
