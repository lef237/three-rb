# frozen_string_literal: true

module Three
  module Backends
    class Base
      def materialize(_object)
        raise NotImplementedError
      end

      def sync(_object)
        raise NotImplementedError
      end

      def dispose(_object, **_options)
        raise NotImplementedError
      end

      def set_renderer_shadow_map(_renderer_handle, **_options)
        raise NotImplementedError
      end

      def traverse_handles(_object, &_block)
        raise NotImplementedError
      end

      def dispose_subtree(_object, **_options)
        raise NotImplementedError
      end

      def create_raycaster
        raise NotImplementedError
      end

      def set_raycaster_from_camera(_raycaster_handle, _coords, _camera)
        raise NotImplementedError
      end

      def intersect_objects(_raycaster_handle, _objects, recursive: false)
        raise NotImplementedError
      end

      def create_animation_mixer(_root_handle)
        raise NotImplementedError
      end

      def animation_mixer_clip_action(_mixer_handle, _clip_handle, _root_handle = nil)
        raise NotImplementedError
      end

      def update_animation_mixer(_mixer_handle, _delta)
        raise NotImplementedError
      end

      def stop_all_animation_actions(_mixer_handle)
        raise NotImplementedError
      end

      def uncache_animation_root(_mixer_handle, _root_handle)
        raise NotImplementedError
      end

      def set_animation_action_property(_action_handle, _name, _value)
        raise NotImplementedError
      end

      def play_animation_action(_action_handle)
        raise NotImplementedError
      end

      def stop_animation_action(_action_handle)
        raise NotImplementedError
      end

      def reset_animation_action(_action_handle)
        raise NotImplementedError
      end

      def fade_in_animation_action(_action_handle, _duration)
        raise NotImplementedError
      end

      def fade_out_animation_action(_action_handle, _duration)
        raise NotImplementedError
      end
    end
  end
end
