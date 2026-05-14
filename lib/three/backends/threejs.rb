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
require_relative "../materials/line_basic_material"
require_relative "../materials/mesh_basic_material"
require_relative "../materials/mesh_lambert_material"
require_relative "../materials/mesh_normal_material"
require_relative "../materials/mesh_phong_material"
require_relative "../materials/mesh_standard_material"
require_relative "../materials/mesh_physical_material"
require_relative "../materials/points_material"
require_relative "../objects/external_object3d"
require_relative "../objects/instanced_mesh"
require_relative "../objects/line"
require_relative "../objects/mesh"
require_relative "../objects/points"
require_relative "../scenes/scene"
require_relative "../textures/cube_texture"
require_relative "../textures/rgbe_texture"
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
        specular_map: :specularMap,
        anisotropy_map: :anisotropyMap,
        clearcoat_map: :clearcoatMap,
        clearcoat_normal_map: :clearcoatNormalMap,
        clearcoat_roughness_map: :clearcoatRoughnessMap,
        transmission_map: :transmissionMap,
        thickness_map: :thicknessMap,
        iridescence_map: :iridescenceMap,
        iridescence_thickness_map: :iridescenceThicknessMap,
        sheen_color_map: :sheenColorMap,
        sheen_roughness_map: :sheenRoughnessMap,
        specular_color_map: :specularColorMap,
        specular_intensity_map: :specularIntensityMap
      }.freeze

      MATERIAL_COLOR_PARAMETERS = %i[color emissive specular attenuationColor sheenColor specularColor].freeze

      attr_reader :adapter, :handles

      def initialize(adapter: nil)
        @adapter = adapter || RubyWasmAdapter.new
        @handles = {}
        @objects_by_handle_key = {}
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

      def set_renderer_shadow_map(renderer_handle, enabled: nil, type: nil, auto_update: nil)
        @adapter.set_renderer_shadow_map(renderer_handle, enabled: enabled, type: type, auto_update: auto_update)
      end

      def set_animation_loop(renderer_handle, callback)
        @adapter.set_animation_loop(renderer_handle, callback)
      end

      def render(renderer_handle, scene, camera)
        scene_handle = sync(scene)
        camera_handle = sync(camera)
        @adapter.render(renderer_handle, scene_handle, camera_handle)
      end

      def create_effect_composer(renderer_handle)
        @adapter.new_effect_composer(renderer_handle)
      end

      def add_effect_composer_pass(composer_handle, pass_handle)
        @adapter.effect_composer_add_pass(composer_handle, pass_handle)
      end

      def set_effect_composer_size(composer_handle, width, height)
        @adapter.effect_composer_set_size(composer_handle, width, height)
      end

      def render_effect_composer(composer_handle, scene = nil, camera = nil)
        sync(scene) if scene
        sync(camera) if camera
        @adapter.effect_composer_render(composer_handle)
      end

      def dispose_effect_composer(composer_handle)
        @adapter.dispose_effect_composer(composer_handle)
      end

      def create_render_pass(scene, camera)
        @adapter.new_render_pass(sync(scene), sync(camera))
      end

      def create_unreal_bloom_pass(resolution, strength, radius, threshold)
        @adapter.new_unreal_bloom_pass(resolution, strength, radius, threshold)
      end

      def create_output_pass
        @adapter.new_output_pass
      end

      def set_postprocessing_pass_property(pass_handle, name, value)
        @adapter.set_postprocessing_pass_property(pass_handle, name, value)
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

      def create_raycaster
        @adapter.new_raycaster
      end

      def set_raycaster_from_camera(raycaster_handle, coords, camera)
        @adapter.set_raycaster_from_camera(raycaster_handle, coords, sync(camera))
      end

      def intersect_objects(raycaster_handle, objects, recursive: false)
        handles = Array(objects).map { |object| sync(object) }
        @adapter.intersect_objects(raycaster_handle, handles, recursive: recursive).map do |intersection|
          normalize_intersection(intersection)
        end
      end

      def create_animation_mixer(root_handle)
        @adapter.new_animation_mixer(root_handle)
      end

      def animation_mixer_clip_action(mixer_handle, clip_handle, root_handle = nil)
        @adapter.animation_mixer_clip_action(mixer_handle, clip_handle, root_handle)
      end

      def update_animation_mixer(mixer_handle, delta)
        @adapter.update_animation_mixer(mixer_handle, delta)
      end

      def stop_all_animation_actions(mixer_handle)
        @adapter.stop_all_animation_actions(mixer_handle)
      end

      def uncache_animation_root(mixer_handle, root_handle)
        @adapter.uncache_animation_root(mixer_handle, root_handle)
      end

      def set_animation_action_property(action_handle, name, value)
        @adapter.set_animation_action_property(action_handle, name, value)
      end

      def play_animation_action(action_handle)
        @adapter.play_animation_action(action_handle)
      end

      def stop_animation_action(action_handle)
        @adapter.stop_animation_action(action_handle)
      end

      def reset_animation_action(action_handle)
        @adapter.reset_animation_action(action_handle)
      end

      def fade_in_animation_action(action_handle, duration)
        @adapter.fade_in_animation_action(action_handle, duration)
      end

      def fade_out_animation_action(action_handle, duration)
        @adapter.fade_out_animation_action(action_handle, duration)
      end

      def materialize(object)
        key = cache_key(object)
        return @handles[key] if key && @handles.key?(key)

        handle = build_handle(object)
        @handles[key] = handle if key
        register_object_handle(object, handle)
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
        handle_key = @adapter.object_handle_key(handle) if handle
        @objects_by_handle_key.delete(handle_key) if handle_key
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

      def register_object_handle(object, handle)
        return unless object.is_a?(Object3D)

        handle_key = @adapter.object_handle_key(handle)
        @objects_by_handle_key[handle_key] = object if handle_key
      end

      def object_for_handle(handle)
        handle_key = @adapter.object_handle_key(handle)
        handle_key ? @objects_by_handle_key[handle_key] : nil
      end

      def normalize_intersection(intersection)
        object_handle = @adapter.intersection_object(intersection)
        {
          distance: @adapter.intersection_distance(intersection),
          point: @adapter.intersection_point(intersection),
          object: object_for_handle(object_handle),
          object_handle: object_handle,
          uv: @adapter.intersection_uv(intersection),
          face_index: @adapter.intersection_face_index(intersection),
          index: @adapter.intersection_index(intersection),
          instance_id: @adapter.intersection_instance_id(intersection),
          raw: intersection
        }
      end
    end
  end
end

require_relative "threejs/parameters"
require_relative "threejs/materialization"
require_relative "threejs/synchronization"
require_relative "threejs/resource_management"
require_relative "threejs/ruby_wasm_adapter"
