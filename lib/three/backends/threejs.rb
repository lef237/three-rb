# frozen_string_literal: true

require_relative "../cameras/orthographic_camera"
require_relative "../cameras/perspective_camera"
require_relative "../core/buffer_geometry"
require_relative "../geometries/box_geometry"
require_relative "../geometries/plane_geometry"
require_relative "../geometries/sphere_geometry"
require_relative "../lights/ambient_light"
require_relative "../lights/directional_light"
require_relative "../materials/mesh_basic_material"
require_relative "../materials/mesh_lambert_material"
require_relative "../materials/mesh_normal_material"
require_relative "../objects/mesh"
require_relative "../scenes/scene"
require_relative "base"

module Three
  module Backends
    class ThreeJS < Base
      attr_reader :adapter, :handles

      def initialize(adapter: nil)
        @adapter = adapter || RubyWasmAdapter.new
        @handles = {}
        @geometry_attribute_names = {}
      end

      def create_renderer(canvas: nil, **options)
        @adapter.new_webgl_renderer({ canvas: canvas }.merge(options))
      end

      def set_renderer_size(renderer_handle, width, height)
        @adapter.set_renderer_size(renderer_handle, width, height)
      end

      def set_clear_color(renderer_handle, color, alpha = 1)
        @adapter.set_clear_color(renderer_handle, color, alpha)
      end

      def set_animation_loop(renderer_handle, callback)
        @adapter.set_animation_loop(renderer_handle, callback)
      end

      def render(renderer_handle, scene, camera)
        scene_handle = sync(scene)
        camera_handle = sync(camera)
        @adapter.render(renderer_handle, scene_handle, camera_handle)
      end

      def materialize(object)
        key = cache_key(object)
        return @handles[key] if key && @handles.key?(key)

        handle = build_handle(object)
        @handles[key] = handle if key
        mark_clean_after_materialize(object)
        handle
      end

      def sync(object)
        handle = materialize(object)

        case object
        when Object3D
          sync_object3d(object, handle)
        when BufferGeometry
          sync_geometry(object, handle)
        when Material
          sync_material(object, handle)
        end

        handle
      end

      def dispose(object)
        key = cache_key(object)
        handle = key ? @handles.delete(key) : nil
        @adapter.dispose(handle) if handle
        handle
      end

      private

      def cache_key(object)
        object.respond_to?(:uuid) ? object.uuid : nil
      end

      def build_handle(object)
        case object
        when OrthographicCamera
          @adapter.new_orthographic_camera(object.left, object.right, object.top, object.bottom, object.near, object.far)
        when PerspectiveCamera
          @adapter.new_perspective_camera(object.fov, object.aspect, object.near, object.far)
        when Scene
          @adapter.new_scene
        when Mesh
          @adapter.new_mesh(materialize(object.geometry), materialize(object.material))
        when AmbientLight
          @adapter.new_ambient_light(object.color.hex, object.intensity)
        when DirectionalLight
          @adapter.new_directional_light(object.color.hex, object.intensity)
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
        when MeshBasicMaterial
          @adapter.new_mesh_basic_material(material_parameters(object))
        when MeshLambertMaterial
          @adapter.new_mesh_lambert_material(material_parameters(object))
        when MeshNormalMaterial
          @adapter.new_mesh_normal_material(material_parameters(object))
        when Group
          @adapter.new_group
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

      def sync_object3d(object, handle)
        if object.dirty_field?(:properties)
          @adapter.set_object_name(handle, object.name)
          @adapter.set_object_visible(handle, object.visible)
        end

        if object.dirty_field?(:transform)
          @adapter.set_object_transform(handle, object.position.to_a, object.quaternion.to_a, object.scale.to_a)
        end

        if object.dirty_field?(:camera)
          sync_camera(object, handle)
        end

        sync_light(object, handle) if object.is_a?(Light) && object.dirty_field?(:light)

        if object.is_a?(Mesh)
          geometry_handle = sync(object.geometry)
          material_handle = sync(object.material) if object.material.respond_to?(:uuid)

          if object.dirty_field?(:mesh)
            @adapter.set_mesh_geometry(handle, geometry_handle)
            @adapter.set_mesh_material(handle, material_handle) if material_handle
          end
        end

        if object.dirty_field?(:children)
          @adapter.clear_children(handle)
          object.children.each do |child|
            child_handle = sync(child)
            @adapter.add_child(handle, child_handle)
          end
        else
          object.children.each { |child| sync(child) }
        end

        object.mark_clean! if object.respond_to?(:mark_clean!)
        handle
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
        @adapter.update_light(handle, object.color.hex, object.intensity)
      end

      def sync_material(material, handle)
        return handle unless material.dirty?

        @adapter.update_material(handle, material_parameters(material))
        material.mark_clean!
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

      def mark_clean_after_materialize(object)
        case object
        when Material
          object.mark_clean!
        when BufferGeometry
          @geometry_attribute_names[object.uuid] = object.attributes.keys
          object.mark_clean!
          object.index&.mark_clean!
          object.attributes.each_value(&:mark_clean!)
        end
      end

      def material_parameters(material)
        parameters = {
          opacity: material.opacity,
          transparent: material.transparent,
          visible: material.visible,
          side: material.side
        }
        parameters[:color] = material.color.hex if material.respond_to?(:color)
        parameters[:wireframe] = material.wireframe if material.respond_to?(:wireframe)
        parameters[:flatShading] = material.flat_shading if material.respond_to?(:flat_shading)
        parameters
      end

      class RubyWasmAdapter
        def initialize(three: nil)
          @three = three || default_three
        end

        def new_webgl_renderer(options = {})
          parameters = stringify_keys(options)
          parameters["canvas"] = resolve_canvas(options[:canvas] || options["canvas"]) if options[:canvas] || options["canvas"]
          @three[:WebGLRenderer].new(parameters)
        end

        def set_renderer_size(renderer, width, height)
          renderer.call(:setSize, width, height)
        end

        def set_clear_color(renderer, color, alpha = 1)
          renderer.call(:setClearColor, color, alpha)
        end

        def set_animation_loop(renderer, callback)
          renderer.call(:setAnimationLoop, callback)
        end

        def render(renderer, scene, camera)
          render_helper = JS.global[:__threeRbRender]
          if render_helper.typeof == "function"
            JS.global[:__threeRbCurrentRenderer] = renderer
            JS.global[:__threeRbCurrentScene] = scene
            JS.global[:__threeRbCurrentCamera] = camera
            JS.global.call(:__threeRbRender)
          else
            renderer.call(:render, scene, camera)
          end
        end

        def new_scene
          @three[:Scene].new
        end

        def new_group
          @three[:Group].new
        end

        def new_object3d
          @three[:Object3D].new
        end

        def new_perspective_camera(fov, aspect, near, far)
          @three[:PerspectiveCamera].new(fov, aspect, near, far)
        end

        def new_orthographic_camera(left, right, top, bottom, near, far)
          @three[:OrthographicCamera].new(left, right, top, bottom, near, far)
        end

        def new_ambient_light(color, intensity)
          @three[:AmbientLight].new(color, intensity)
        end

        def new_directional_light(color, intensity)
          @three[:DirectionalLight].new(color, intensity)
        end

        def new_mesh(geometry, material)
          @three[:Mesh].new(geometry, material)
        end

        def set_mesh_geometry(mesh, geometry)
          mesh[:geometry] = geometry
        end

        def set_mesh_material(mesh, material)
          mesh[:material] = material
        end

        def new_box_geometry(width, height, depth, width_segments, height_segments, depth_segments)
          @three[:BoxGeometry].new(width, height, depth, width_segments, height_segments, depth_segments)
        end

        def new_plane_geometry(width, height, width_segments, height_segments)
          @three[:PlaneGeometry].new(width, height, width_segments, height_segments)
        end

        def new_sphere_geometry(radius, width_segments, height_segments, phi_start, phi_length, theta_start, theta_length)
          @three[:SphereGeometry].new(radius, width_segments, height_segments, phi_start, phi_length, theta_start, theta_length)
        end

        def new_buffer_geometry
          @three[:BufferGeometry].new
        end

        def new_buffer_attribute(component_type, array, item_size, normalized)
          typed_array = typed_array(component_type, array)
          @three[:BufferAttribute].new(typed_array, item_size, normalized)
        end

        def set_geometry_index(geometry, attribute)
          geometry.call(:setIndex, attribute)
        end

        def set_geometry_attribute(geometry, name, attribute)
          geometry.call(:setAttribute, name.to_s, attribute)
        end

        def delete_geometry_attribute(geometry, name)
          geometry.call(:deleteAttribute, name.to_s)
        end

        def clear_geometry_groups(geometry)
          geometry.call(:clearGroups)
        end

        def add_geometry_group(geometry, start, count, material_index)
          geometry.call(:addGroup, start, count, material_index)
        end

        def set_geometry_draw_range(geometry, start, count)
          geometry.call(:setDrawRange, start, count)
        end

        def new_mesh_basic_material(parameters)
          @three[:MeshBasicMaterial].new(stringify_keys(parameters))
        end

        def new_mesh_lambert_material(parameters)
          @three[:MeshLambertMaterial].new(stringify_keys(parameters))
        end

        def new_mesh_normal_material(parameters)
          @three[:MeshNormalMaterial].new(stringify_keys(parameters))
        end

        def set_object_name(object, name)
          object[:name] = name
        end

        def set_object_visible(object, visible)
          object[:visible] = visible
        end

        def set_object_transform(object, position, quaternion, scale)
          object[:position].call(:set, *position)
          object[:quaternion].call(:set, *quaternion)
          object[:scale].call(:set, *scale)
        end

        def update_perspective_camera(camera, fov, aspect, near, far, zoom)
          camera[:fov] = fov
          camera[:aspect] = aspect
          camera[:near] = near
          camera[:far] = far
          camera[:zoom] = zoom
          camera.call(:updateProjectionMatrix)
        end

        def update_orthographic_camera(camera, left, right, top, bottom, near, far, zoom)
          camera[:left] = left
          camera[:right] = right
          camera[:top] = top
          camera[:bottom] = bottom
          camera[:near] = near
          camera[:far] = far
          camera[:zoom] = zoom
          camera.call(:updateProjectionMatrix)
        end

        def update_light(light, color, intensity)
          light[:color].call(:setHex, color)
          light[:intensity] = intensity
        end

        def update_material(material, parameters)
          parameters.each do |key, value|
            if key == :color
              material[:color].call(:setHex, value)
            else
              material[key] = value
            end
          end
          material[:needsUpdate] = true
        end

        def add_child(parent, child)
          parent.call(:add, child)
        end

        def clear_children(parent)
          parent.call(:clear)
        end

        def dispose(handle)
          handle.call(:dispose) if handle.respond_to?(:call)
        end

        private

        def default_three
          require "js"
          JS.global[:THREE]
        rescue LoadError
          raise RuntimeError, "Three::Backends::ThreeJS requires ruby.wasm's js gem or an injected adapter"
        end

        def resolve_canvas(canvas)
          return canvas unless canvas.is_a?(String)

          JS.global[:document].call(:querySelector, canvas)
        end

        def typed_array(component_type, array)
          constructor =
            case component_type
            when :float32 then JS.global[:Float32Array]
            when :uint16 then JS.global[:Uint16Array]
            when :uint32 then JS.global[:Uint32Array]
            else JS.global[:Array]
            end
          constructor.new(array)
        end

        def stringify_keys(hash)
          hash.each_with_object({}) do |(key, value), result|
            result[key.to_s] = value
          end
        end
      end
    end
  end
end
