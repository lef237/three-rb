# frozen_string_literal: true

require_relative "../cameras/perspective_camera"
require_relative "../core/buffer_geometry"
require_relative "../geometries/box_geometry"
require_relative "../materials/mesh_basic_material"
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
      end

      def create_renderer(canvas: nil, **options)
        @adapter.new_webgl_renderer({ canvas: canvas }.merge(options))
      end

      def set_renderer_size(renderer_handle, width, height)
        @adapter.set_renderer_size(renderer_handle, width, height)
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
        handle
      end

      def sync(object)
        handle = materialize(object)

        case object
        when Object3D
          sync_object3d(object, handle)
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
        when PerspectiveCamera
          @adapter.new_perspective_camera(object.fov, object.aspect, object.near, object.far)
        when Scene
          @adapter.new_scene
        when Mesh
          @adapter.new_mesh(materialize(object.geometry), materialize(object.material))
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
        when BufferGeometry
          build_buffer_geometry(object)
        when MeshBasicMaterial
          @adapter.new_mesh_basic_material(material_parameters(object))
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
        @adapter.set_object_name(handle, object.name)
        @adapter.set_object_visible(handle, object.visible)
        @adapter.set_object_transform(handle, object.position.to_a, object.quaternion.to_a, object.scale.to_a)

        if object.is_a?(PerspectiveCamera)
          @adapter.update_perspective_camera(handle, object.fov, object.aspect, object.near, object.far, object.zoom)
        end

        if object.is_a?(Mesh)
          sync(object.geometry)
          sync(object.material) if object.material.respond_to?(:uuid)
        end

        object.children.each do |child|
          child_handle = sync(child)
          @adapter.add_child(handle, child_handle)
        end

        handle
      end

      def sync_material(material, handle)
        @adapter.update_material(handle, material_parameters(material))
        handle
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
        parameters
      end

      class RubyWasmAdapter
        def initialize(three: nil)
          @three = three || default_three
        end

        def new_webgl_renderer(options = {})
          parameters = {}
          parameters[:canvas] = resolve_canvas(options[:canvas]) if options[:canvas]
          @three[:WebGLRenderer].new(parameters)
        end

        def set_renderer_size(renderer, width, height)
          renderer.call(:setSize, width, height)
        end

        def set_animation_loop(renderer, callback)
          renderer.call(:setAnimationLoop, callback)
        end

        def render(renderer, scene, camera)
          renderer.call(:render, scene, camera)
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

        def new_mesh(geometry, material)
          @three[:Mesh].new(geometry, material)
        end

        def new_box_geometry(width, height, depth, width_segments, height_segments, depth_segments)
          @three[:BoxGeometry].new(width, height, depth, width_segments, height_segments, depth_segments)
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

        def add_geometry_group(geometry, start, count, material_index)
          geometry.call(:addGroup, start, count, material_index)
        end

        def set_geometry_draw_range(geometry, start, count)
          geometry.call(:setDrawRange, start, count)
        end

        def new_mesh_basic_material(parameters)
          @three[:MeshBasicMaterial].new(parameters)
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

        def update_material(material, parameters)
          parameters.each { |key, value| material[key] = value }
          material[:needsUpdate] = true
        end

        def add_child(parent, child)
          parent.call(:add, child)
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
      end
    end
  end
end
