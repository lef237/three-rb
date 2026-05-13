# frozen_string_literal: true

module Three
  module Backends
    class ThreeJS
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

        def set_renderer_shadow_map(renderer, enabled: nil, type: nil, auto_update: nil)
          shadow_map = renderer[:shadowMap]
          shadow_map[:enabled] = enabled unless enabled.nil?
          shadow_map[:type] = type unless type.nil?
          shadow_map[:autoUpdate] = auto_update unless auto_update.nil?
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

        def new_raycaster
          @three[:Raycaster].new
        end

        def set_raycaster_from_camera(raycaster, coords, camera)
          raycaster.call(:setFromCamera, @three[:Vector2].new(*coords), camera)
        end

        def intersect_objects(raycaster, objects, recursive: false)
          raycaster.call(:intersectObjects, js_array(objects), recursive).to_a
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

        def new_line(geometry, material)
          @three[:Line].new(geometry, material)
        end

        def new_points(geometry, material)
          @three[:Points].new(geometry, material)
        end

        def new_instanced_mesh(geometry, material, count)
          @three[:InstancedMesh].new(geometry, material, count)
        end

        def set_object_geometry(object, geometry)
          object[:geometry] = geometry
        end

        def set_object_material(object, material)
          object[:material] = material
        end

        def set_mesh_geometry(mesh, geometry)
          set_object_geometry(mesh, geometry)
        end

        def set_mesh_material(mesh, material)
          set_object_material(mesh, material)
        end

        def set_object_layers(object, mask)
          object[:layers][:mask] = mask if js_present?(object[:layers])
        end

        def set_instanced_mesh_count(mesh, count)
          mesh[:count] = count
        end

        def set_instanced_mesh_matrix_at(mesh, index, elements)
          matrix = @three[:Matrix4].new
          matrix.call(:fromArray, js_array(elements))
          mesh.call(:setMatrixAt, index, matrix)
        end

        def set_instanced_mesh_instance_matrix_needs_update(mesh, value)
          mesh[:instanceMatrix][:needsUpdate] = value
        end

        def set_instanced_mesh_color_at(mesh, index, color)
          mesh.call(:setColorAt, index, @three[:Color].new(*color))
        end

        def set_instanced_mesh_instance_color_needs_update(mesh, value)
          instance_color = mesh[:instanceColor]
          instance_color[:needsUpdate] = value if js_present?(instance_color)
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

        def new_line_basic_material(parameters)
          @three[:LineBasicMaterial].new(stringify_keys(parameters))
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

        def new_points_material(parameters)
          @three[:PointsMaterial].new(stringify_keys(parameters))
        end

        def set_object_name(object, name)
          object[:name] = name
        end

        def set_object_visible(object, visible)
          object[:visible] = visible
        end

        def set_object_shadow(object, cast_shadow, receive_shadow)
          object[:castShadow] = cast_shadow
          object[:receiveShadow] = receive_shadow
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

        def update_light_shadow(light, parameters)
          shadow = light[:shadow]
          return unless js_present?(shadow)

          if parameters[:map_size]
            shadow[:mapSize].call(:set, *parameters[:map_size])
          end
          shadow[:bias] = parameters[:bias] unless parameters[:bias].nil?
          shadow[:normalBias] = parameters[:normal_bias] unless parameters[:normal_bias].nil?
          shadow[:radius] = parameters[:radius] unless parameters[:radius].nil?

          camera = shadow[:camera]
          if js_present?(camera) && parameters[:camera]
            parameters[:camera].each do |key, value|
              camera[key] = value
            end
            camera.call(:updateProjectionMatrix)
          end
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

        def object_handle_key(object)
          return nil unless js_present?(object)

          uuid = object[:uuid]
          js_present?(uuid) ? uuid.to_s : nil
        end

        def intersection_distance(intersection)
          value = intersection[:distance]
          js_present?(value) ? value.to_f : nil
        end

        def intersection_point(intersection)
          point = intersection[:point]
          js_present?(point) ? js_vector_to_a(point, 3) : nil
        end

        def intersection_object(intersection)
          intersection[:object]
        end

        def intersection_uv(intersection)
          uv = intersection[:uv]
          js_present?(uv) ? js_vector_to_a(uv, 2) : nil
        end

        def intersection_face_index(intersection)
          value = intersection[:faceIndex]
          js_present?(value) ? value.to_i : nil
        end

        def intersection_index(intersection)
          value = intersection[:index]
          js_present?(value) ? value.to_i : nil
        end

        def intersection_instance_id(intersection)
          value = intersection[:instanceId]
          js_present?(value) ? value.to_i : nil
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
