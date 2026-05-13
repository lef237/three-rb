# frozen_string_literal: true

require "json"

module Three
  module Loaders
    class ThreeJSONLoader
      def parse(input)
        data = input.is_a?(String) ? JSON.parse(input) : input
        @textures = build_resource_map(value(data, :textures)) { |entry| build_texture(entry) }
        @geometries = build_resource_map(value(data, :geometries)) { |entry| build_geometry(entry) }
        @materials = build_resource_map(value(data, :materials)) { |entry| build_material(entry) }
        build_object(value(data, :object))
      end

      private

      def build_resource_map(entries)
        Array(entries).each_with_object({}) do |entry, result|
          result[value(entry, :uuid)] = yield(entry)
        end
      end

      def build_texture(entry)
        case value(entry, :type)
        when "CubeTexture"
          CubeTexture.new(
            value(entry, :sources) || value(entry, :source),
            **texture_parameters(entry)
          )
        else
          Texture.new(value(entry, :source), **texture_parameters(entry))
        end
      end

      def texture_parameters(entry)
        {
          flip_y: value(entry, :flip_y),
          wrap_s: value(entry, :wrap_s),
          wrap_t: value(entry, :wrap_t),
          mag_filter: value(entry, :mag_filter),
          min_filter: value(entry, :min_filter),
          repeat: value(entry, :repeat)
        }.compact
      end

      def build_geometry(entry)
        case value(entry, :type)
        when "BoxGeometry"
          parameters = value(entry, :parameters) || {}
          BoxGeometry.new(
            value(parameters, :width) || 1,
            value(parameters, :height) || 1,
            value(parameters, :depth) || 1,
            width_segments: value(parameters, :width_segments) || 1,
            height_segments: value(parameters, :height_segments) || 1,
            depth_segments: value(parameters, :depth_segments) || 1
          )
        when "PlaneGeometry"
          parameters = value(entry, :parameters) || {}
          PlaneGeometry.new(
            value(parameters, :width) || 1,
            value(parameters, :height) || 1,
            width_segments: value(parameters, :width_segments) || 1,
            height_segments: value(parameters, :height_segments) || 1
          )
        when "SphereGeometry"
          parameters = value(entry, :parameters) || {}
          SphereGeometry.new(
            value(parameters, :radius) || 1,
            width_segments: value(parameters, :width_segments) || 32,
            height_segments: value(parameters, :height_segments) || 16,
            phi_start: value(parameters, :phi_start) || 0,
            phi_length: value(parameters, :phi_length) || Math::PI * 2,
            theta_start: value(parameters, :theta_start) || 0,
            theta_length: value(parameters, :theta_length) || Math::PI
          )
        else
          build_buffer_geometry(entry)
        end
      end

      def build_buffer_geometry(entry)
        geometry = BufferGeometry.new
        geometry.name = value(entry, :name) if value(entry, :name)
        geometry.set_index(build_buffer_attribute(value(entry, :index))) if value(entry, :index)

        (value(entry, :attributes) || {}).each do |name, attribute_entry|
          geometry.set_attribute(name.to_sym, build_buffer_attribute(attribute_entry))
        end

        Array(value(entry, :groups)).each do |group|
          geometry.add_group(
            value(group, :start),
            value(group, :count),
            value(group, :material_index) || 0
          )
        end

        geometry
      end

      def build_buffer_attribute(entry)
        component_type = (value(entry, :component_type) || :generic).to_sym
        array = value(entry, :array) || []
        item_size = value(entry, :item_size)
        normalized = value(entry, :normalized) || false

        case component_type
        when :float32
          Float32BufferAttribute.new(array, item_size, normalized)
        when :uint16
          Uint16BufferAttribute.new(array, item_size, normalized)
        when :uint32
          Uint32BufferAttribute.new(array, item_size, normalized)
        else
          BufferAttribute.new(array, item_size, normalized, component_type: component_type)
        end
      end

      def build_material(entry)
        parameters = material_parameters(entry)
        case value(entry, :type)
        when "MeshBasicMaterial"
          MeshBasicMaterial.new(parameters)
        when "LineBasicMaterial"
          LineBasicMaterial.new(parameters)
        when "MeshLambertMaterial"
          MeshLambertMaterial.new(parameters)
        when "MeshNormalMaterial"
          MeshNormalMaterial.new(parameters)
        when "MeshPhongMaterial"
          MeshPhongMaterial.new(parameters)
        when "MeshStandardMaterial"
          MeshStandardMaterial.new(parameters)
        when "PointsMaterial"
          PointsMaterial.new(parameters)
        else
          Material.new(parameters)
        end
      end

      def material_parameters(entry)
        parameters = {}
        %i[
          name
          side
          opacity
          transparent
          visible
          vertex_colors
          color
          emissive
          specular
          shininess
          roughness
          metalness
          wireframe
          wireframe_linewidth
          linewidth
          linecap
          linejoin
          fog
          flat_shading
          size
          size_attenuation
        ].each do |key|
          next unless has_value?(entry, key)

          parameters[key] = value(entry, key)
        end

        texture_slots(entry).each do |slot|
          uuid = value(entry, slot)
          parameters[slot] = @textures[uuid] if uuid
        end
        parameters
      end

      def texture_slots(entry)
        %i[
          map
          alpha_map
          ao_map
          bump_map
          displacement_map
          emissive_map
          env_map
          light_map
          metalness_map
          normal_map
          roughness_map
          specular_map
        ].select { |slot| has_value?(entry, slot) }
      end

      def build_object(entry)
        object = instantiate_object(entry)
        apply_object_properties(object, entry)
        Array(value(entry, :children)).each { |child| object.add(build_object(child)) }
        object
      end

      def instantiate_object(entry)
        case value(entry, :type)
        when "Scene"
          build_scene(entry)
        when "PerspectiveCamera"
          PerspectiveCamera.new(
            value(entry, :fov) || 50,
            aspect: value(entry, :aspect) || 1,
            near: value(entry, :near) || 0.1,
            far: value(entry, :far) || 2000
          )
        when "OrthographicCamera"
          OrthographicCamera.new(
            value(entry, :left),
            value(entry, :right),
            value(entry, :top),
            value(entry, :bottom),
            near: value(entry, :near) || 0.1,
            far: value(entry, :far) || 2000
          )
        when "AmbientLight"
          AmbientLight.new(value(entry, :color) || 0xffffff, value(entry, :intensity) || 1)
        when "DirectionalLight"
          build_directional_light(entry)
        when "PointLight"
          PointLight.new(
            value(entry, :color) || 0xffffff,
            value(entry, :intensity) || 1,
            value(entry, :distance) || 0,
            value(entry, :decay) || 2
          )
        when "HemisphereLight"
          HemisphereLight.new(
            value(entry, :color) || 0xffffff,
            value(entry, :ground_color) || 0xffffff,
            value(entry, :intensity) || 1
          )
        when "InstancedMesh"
          build_instanced_mesh(entry)
        when "Mesh"
          Mesh.new(@geometries[value(entry, :geometry)], material_reference(entry))
        when "Line"
          Line.new(@geometries[value(entry, :geometry)], material_reference(entry))
        when "Points"
          Points.new(@geometries[value(entry, :geometry)], material_reference(entry))
        when "Group"
          Group.new
        else
          Object3D.new
        end
      end

      def build_scene(entry)
        scene = Scene.new
        scene.background = @textures[value(entry, :background)] if value(entry, :background)
        scene.environment = @textures[value(entry, :environment)] if value(entry, :environment)
        scene
      end

      def build_directional_light(entry)
        light = DirectionalLight.new(value(entry, :color) || 0xffffff, value(entry, :intensity) || 1)
        camera = value(entry, :shadow_camera)
        light.set_shadow_camera(**symbolize_keys(camera)) if camera
        light
      end

      def build_instanced_mesh(entry)
        mesh = InstancedMesh.new(
          @geometries[value(entry, :geometry)],
          material_reference(entry),
          value(entry, :capacity) || value(entry, :count) || 1
        )
        mesh.count = value(entry, :count) if has_value?(entry, :count)

        Array(value(entry, :instance_matrices)).each_with_index do |matrix, index|
          mesh.set_matrix_at(index, matrix)
        end
        Array(value(entry, :instance_colors)).each_with_index do |color, index|
          mesh.set_color_at(index, color) if color
        end
        mesh
      end

      def material_reference(entry)
        material = value(entry, :material)
        return material.map { |uuid| @materials[uuid] } if material.is_a?(Array)

        @materials[material]
      end

      def apply_object_properties(object, entry)
        object.name = value(entry, :name) if has_value?(entry, :name)
        object.visible = value(entry, :visible) if has_value?(entry, :visible)
        object.layers.mask = value(entry, :layers) if has_value?(entry, :layers)
        object.cast_shadow = value(entry, :cast_shadow) if has_value?(entry, :cast_shadow)
        object.receive_shadow = value(entry, :receive_shadow) if has_value?(entry, :receive_shadow)
        object.matrix_auto_update = value(entry, :matrix_auto_update) if has_value?(entry, :matrix_auto_update)
        object.user_data = value(entry, :user_data) || {}

        object.position.set(*value(entry, :position)) if value(entry, :position)
        object.quaternion.set(*value(entry, :quaternion)) if value(entry, :quaternion)
        object.scale.set(*value(entry, :scale)) if value(entry, :scale)

        apply_camera_properties(object, entry)
        apply_light_properties(object, entry)
        object
      end

      def apply_camera_properties(object, entry)
        return unless object.is_a?(Camera)

        object.zoom = value(entry, :zoom) if has_value?(entry, :zoom)
        object.update_projection_matrix if object.respond_to?(:update_projection_matrix)
      end

      def apply_light_properties(object, entry)
        return unless object.is_a?(Light)

        object.shadow_map_size = value(entry, :shadow_map_size) if value(entry, :shadow_map_size)
        object.shadow_bias = value(entry, :shadow_bias) if has_value?(entry, :shadow_bias)
        object.shadow_normal_bias = value(entry, :shadow_normal_bias) if has_value?(entry, :shadow_normal_bias)
        object.shadow_radius = value(entry, :shadow_radius) if has_value?(entry, :shadow_radius)
      end

      def has_value?(hash, key)
        hash.key?(key) || hash.key?(key.to_s)
      end

      def value(hash, key)
        return nil unless hash
        return hash[key] if hash.key?(key)

        hash[key.to_s]
      end

      def symbolize_keys(hash)
        return {} unless hash

        hash.each_with_object({}) do |(key, value), result|
          result[key.to_sym] = value
        end
      end
    end
  end
end
