# frozen_string_literal: true

require_relative "../cameras/orthographic_camera"
require_relative "../cameras/perspective_camera"
require_relative "../core/buffer_geometry"
require_relative "../geometries/box_geometry"
require_relative "../geometries/plane_geometry"
require_relative "../geometries/sphere_geometry"
require_relative "../lights/ambient_light"
require_relative "../lights/directional_light"
require_relative "../lights/hemisphere_light"
require_relative "../lights/point_light"
require_relative "../materials/mesh_basic_material"
require_relative "../materials/mesh_lambert_material"
require_relative "../materials/mesh_normal_material"
require_relative "../materials/mesh_phong_material"
require_relative "../materials/mesh_standard_material"
require_relative "../objects/external_object3d"
require_relative "../objects/mesh"
require_relative "../scenes/scene"
require_relative "../textures/cube_texture"
require_relative "../textures/texture"
require_relative "base"

module Three
  module Backends
    class ThreeJS < Base
      MATERIAL_TEXTURE_PARAMETERS = {
        map: :map,
        alpha_map: :alphaMap,
        ao_map: :aoMap,
        bump_map: :bumpMap,
        displacement_map: :displacementMap,
        emissive_map: :emissiveMap,
        env_map: :envMap,
        light_map: :lightMap,
        metalness_map: :metalnessMap,
        normal_map: :normalMap,
        roughness_map: :roughnessMap,
        specular_map: :specularMap
      }.freeze

      MATERIAL_COLOR_PARAMETERS = %i[color emissive specular].freeze

      attr_reader :adapter, :handles

      def initialize(adapter: nil)
        @adapter = adapter || RubyWasmAdapter.new
        @handles = {}
        @geometry_attribute_names = {}
      end

      def create_renderer(canvas: nil, **options)
        @adapter.new_webgl_renderer({ canvas: canvas }.merge(options))
      end

      def renderer_dom_element(renderer_handle)
        @adapter.renderer_dom_element(renderer_handle)
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

      def create_orbit_controls(camera, dom_element = nil)
        @adapter.new_orbit_controls(camera, dom_element)
      end

      def set_control_property(control_handle, name, value)
        @adapter.set_control_property(control_handle, name, value)
      end

      def set_orbit_controls_target(control_handle, target)
        @adapter.set_orbit_controls_target(control_handle, target)
      end

      def update_controls(control_handle)
        @adapter.update_controls(control_handle)
      end

      def dispose_controls(control_handle)
        @adapter.dispose_controls(control_handle)
      end

      def sync_object_transform_from_handle(object)
        handle = materialize(object)
        position, quaternion, scale = @adapter.object_transform(handle)
        object.position.set(*position)
        object.quaternion.set(*quaternion)
        object.scale.set(*scale)
        object.mark_clean!(:transform) if object.respond_to?(:mark_clean!)
        object
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
        when Texture
          sync_texture(object, handle)
        when Material
          sync_material(object, handle)
        end

        handle
      end

      def dispose(object, dispose_textures: false)
        dispose_material_textures(object) if dispose_textures && object.is_a?(Material)

        key = cache_key(object)
        handle = key ? @handles.delete(key) : nil
        @adapter.dispose(handle) if handle
        handle
      end

      def traverse_handles(object, &block)
        return enum_for(:traverse_handles, object) unless block

        handle = object3d_handle(object)
        @adapter.traverse_object3d(handle, block)
        handle
      end

      def dispose_subtree(
        object,
        remove: true,
        dispose_geometries: true,
        dispose_materials: true,
        dispose_textures: false,
        dispose_skeletons: true
      )
        handle = object3d_handle(object)
        @adapter.dispose_object3d_subtree(
          handle,
          remove: remove,
          dispose_geometries: dispose_geometries,
          dispose_materials: dispose_materials,
          dispose_textures: dispose_textures,
          dispose_skeletons: dispose_skeletons
        )
        object.remove_from_parent if remove && object.respond_to?(:remove_from_parent)
        release_cached_subtree_handles(
          object,
          dispose_geometries: dispose_geometries,
          dispose_materials: dispose_materials,
          dispose_textures: dispose_textures
        )
        handle
      end

      private

      def object3d_handle(object)
        raise TypeError, "object must be a Three::Object3D" unless object.is_a?(Object3D)

        sync(object)
      end

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
        when CubeTexture
          @adapter.load_cube_texture(object.sources, texture_parameters(object))
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
        when MeshBasicMaterial
          @adapter.new_mesh_basic_material(material_parameters(object))
        when MeshLambertMaterial
          @adapter.new_mesh_lambert_material(material_parameters(object))
        when MeshNormalMaterial
          @adapter.new_mesh_normal_material(material_parameters(object))
        when MeshPhongMaterial
          @adapter.new_mesh_phong_material(material_parameters(object))
        when MeshStandardMaterial
          @adapter.new_mesh_standard_material(material_parameters(object))
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

      def sync_object3d(object, handle)
        sync_scene(object, handle) if object.is_a?(Scene) && (object.dirty_field?(:scene) || scene_resource_dirty?(object))

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
        @handles.delete(key) if key

        if object.is_a?(Mesh)
          release_cached_resource(object.geometry) if dispose_geometries
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

      def material_parameters(material)
        parameters = {
          opacity: material.opacity,
          transparent: material.transparent,
          visible: material.visible,
          side: material.side
        }
        parameters[:color] = material.color.hex if material.respond_to?(:color)
        parameters[:emissive] = material.emissive.hex if material.respond_to?(:emissive)
        parameters[:specular] = material.specular.hex if material.respond_to?(:specular)
        parameters[:shininess] = material.shininess if material.respond_to?(:shininess)
        parameters[:roughness] = material.roughness if material.respond_to?(:roughness)
        parameters[:metalness] = material.metalness if material.respond_to?(:metalness)
        material_texture_parameters(material).each do |ruby_name, threejs_name|
          texture = material.public_send(ruby_name)
          parameters[threejs_name] = texture ? sync(texture) : nil
        end
        parameters[:wireframe] = material.wireframe if material.respond_to?(:wireframe)
        parameters[:flatShading] = material.flat_shading if material.respond_to?(:flat_shading)
        parameters
      end

      def material_texture_parameters(material)
        MATERIAL_TEXTURE_PARAMETERS.select { |ruby_name, _threejs_name| material.respond_to?(ruby_name) }
      end

      def texture_parameters(texture)
        {
          flip_y: texture.flip_y,
          wrap_s: texture.wrap_s,
          wrap_t: texture.wrap_t,
          mag_filter: texture.mag_filter,
          min_filter: texture.min_filter,
          repeat: texture.repeat.to_a
        }
      end

      class RubyWasmAdapter
        TEXTURE_SLOTS = %w[
          map
          normalMap
          roughnessMap
          metalnessMap
          aoMap
          emissiveMap
          alphaMap
          bumpMap
          displacementMap
          envMap
          lightMap
          specularMap
          clearcoatMap
          clearcoatNormalMap
          clearcoatRoughnessMap
          transmissionMap
          thicknessMap
          iridescenceMap
          iridescenceThicknessMap
          sheenColorMap
          sheenRoughnessMap
          specularColorMap
          specularIntensityMap
        ].freeze

        def initialize(three: nil)
          @three = three || default_three
        end

        def new_webgl_renderer(options = {})
          parameters = stringify_keys(options)
          parameters["canvas"] = resolve_canvas(options[:canvas] || options["canvas"]) if options[:canvas] || options["canvas"]
          @three[:WebGLRenderer].new(parameters)
        end

        def renderer_dom_element(renderer)
          renderer[:domElement]
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

        def new_orbit_controls(camera, dom_element)
          constructor = orbit_controls_constructor
          dom_element ? constructor.new(camera, dom_element) : constructor.new(camera)
        end

        def load_texture(source, parameters = {})
          texture = @three[:TextureLoader].new.call(:load, source)
          update_texture(texture, parameters)
          texture
        end

        def load_cube_texture(sources, parameters = {})
          texture = @three[:CubeTextureLoader].new.call(:load, js_array(sources))
          update_texture(texture, parameters)
          texture
        end

        def load_gltf(source)
          gltf_loader_constructor.new.call(:loadAsync, source)
        end

        def update_texture(texture, parameters)
          texture[:flipY] = parameters[:flip_y] unless parameters[:flip_y].nil?
          texture[:wrapS] = parameters[:wrap_s] unless parameters[:wrap_s].nil?
          texture[:wrapT] = parameters[:wrap_t] unless parameters[:wrap_t].nil?
          texture[:magFilter] = parameters[:mag_filter] unless parameters[:mag_filter].nil?
          texture[:minFilter] = parameters[:min_filter] unless parameters[:min_filter].nil?
          texture[:repeat].call(:set, *parameters[:repeat]) if parameters[:repeat]
          texture[:needsUpdate] = true
          texture
        end

        def set_control_property(control, name, value)
          control[name] = value
        end

        def set_orbit_controls_target(control, target)
          control[:target].call(:set, *target)
        end

        def update_controls(control)
          control.call(:update)
        end

        def dispose_controls(control)
          control.call(:dispose)
        end

        def object_transform(object)
          [
            js_vector_to_a(object[:position], 3),
            js_vector_to_a(object[:quaternion], 4),
            js_vector_to_a(object[:scale], 3)
          ]
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

        def new_point_light(color, intensity, distance, decay)
          @three[:PointLight].new(color, intensity, distance, decay)
        end

        def new_hemisphere_light(sky_color, ground_color, intensity)
          @three[:HemisphereLight].new(sky_color, ground_color, intensity)
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

        def new_mesh_phong_material(parameters)
          @three[:MeshPhongMaterial].new(stringify_keys(parameters))
        end

        def new_mesh_standard_material(parameters)
          @three[:MeshStandardMaterial].new(stringify_keys(parameters))
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

        def update_point_light(light, color, intensity, distance, decay)
          update_light(light, color, intensity)
          light[:distance] = distance
          light[:decay] = decay
        end

        def update_hemisphere_light(light, sky_color, ground_color, intensity)
          update_light(light, sky_color, intensity)
          light[:groundColor].call(:setHex, ground_color)
        end

        def update_material(material, parameters)
          parameters.each do |key, value|
            if MATERIAL_COLOR_PARAMETERS.include?(key)
              material[key].call(:setHex, value)
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

        def set_scene_background(scene, background)
          scene[:background] = background
        end

        def set_scene_environment(scene, environment)
          scene[:environment] = environment
        end

        def dispose(handle)
          handle.call(:dispose) if handle.respond_to?(:call)
        end

        def traverse_object3d(object, callback)
          object.call(:traverse, callback)
          object
        end

        def dispose_object3d_subtree(
          object,
          remove: true,
          dispose_geometries: true,
          dispose_materials: true,
          dispose_textures: false,
          dispose_skeletons: true
        )
          resources = {
            geometries: JS.global[:Set].new,
            materials: JS.global[:Set].new,
            textures: JS.global[:Set].new,
            skeletons: JS.global[:Set].new
          }

          traverse_object3d(object, proc do |node|
            collect_object3d_resources(
              node,
              resources,
              dispose_geometries: dispose_geometries,
              dispose_materials: dispose_materials,
              dispose_textures: dispose_textures,
              dispose_skeletons: dispose_skeletons
            )
          end)

          remove_from_js_parent(object) if remove

          dispose_js_set(resources[:geometries])
          dispose_js_set(resources[:materials])
          dispose_js_set(resources[:textures])
          dispose_js_set(resources[:skeletons])
          object
        end

        private

        def default_three
          require "js"
          JS.global[:THREE]
        rescue LoadError
          raise RuntimeError, "Three::Backends::ThreeJS requires ruby.wasm's js gem or an injected adapter"
        end

        def orbit_controls_constructor
          require "js"
          constructor = JS.global[:THREE_ORBIT_CONTROLS]
          raise RuntimeError, "Three::Controls::OrbitControls requires globalThis.THREE_ORBIT_CONTROLS" if constructor.typeof == "undefined"

          constructor
        rescue LoadError
          raise RuntimeError, "Three::Controls::OrbitControls requires ruby.wasm's js gem or an injected adapter"
        end

        def gltf_loader_constructor
          require "js"
          constructor = JS.global[:THREE_GLTF_LOADER]
          raise RuntimeError, "Three::Loaders::GLTFLoader requires globalThis.THREE_GLTF_LOADER" if constructor.typeof == "undefined"

          constructor
        rescue LoadError
          raise RuntimeError, "Three::Loaders::GLTFLoader requires ruby.wasm's js gem or an injected adapter"
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

        def js_array(values)
          array = JS.global[:Array].new
          values.each { |value| array.call(:push, value) }
          array
        end

        def stringify_keys(hash)
          hash.each_with_object({}) do |(key, value), result|
            result[key.to_s] = value
          end
        end

        def js_vector_to_a(vector, length)
          array = vector.call(:toArray)
          length.times.map { |index| array[index].to_f }
        end

        def collect_object3d_resources(node, resources, dispose_geometries:, dispose_materials:, dispose_textures:, dispose_skeletons:)
          if dispose_geometries
            geometry = node[:geometry]
            resources[:geometries].call(:add, geometry) if js_present?(geometry)
          end

          if dispose_materials
            collect_materials(node[:material], resources, dispose_textures: dispose_textures)
          end

          if dispose_textures
            collect_texture(node[:background], resources)
            collect_texture(node[:environment], resources)
          end

          return unless dispose_skeletons

          skeleton = node[:skeleton]
          resources[:skeletons].call(:add, skeleton) if js_present?(skeleton)
        end

        def collect_materials(material, resources, dispose_textures:)
          return unless js_present?(material)

          if JS.global[:Array].call(:isArray, material) == JS::True
            material[:length].to_i.times do |index|
              collect_material(material[index], resources, dispose_textures: dispose_textures)
            end
          else
            collect_material(material, resources, dispose_textures: dispose_textures)
          end
        end

        def collect_material(material, resources, dispose_textures:)
          return unless js_present?(material)

          resources[:materials].call(:add, material)
          return unless dispose_textures

          TEXTURE_SLOTS.each { |slot| collect_texture(material[slot], resources) }
        end

        def collect_texture(texture, resources)
          resources[:textures].call(:add, texture) if js_present?(texture)
        end

        def dispose_js_set(resources)
          resources.call(:forEach, proc { |resource| dispose(resource) })
        end

        def remove_from_js_parent(object)
          parent = object[:parent]
          parent.call(:remove, object) if js_present?(parent)
        end

        def js_present?(object)
          return false if object.nil?
          return false if object == JS::Undefined || object == JS::Null
          return false if object.respond_to?(:typeof) && object.typeof == "undefined"

          true
        end
      end
    end
  end
end
