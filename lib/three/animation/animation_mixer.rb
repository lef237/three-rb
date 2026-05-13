# frozen_string_literal: true

require_relative "../backends/threejs"
require_relative "animation_action"

module Three
  class AnimationMixer
    attr_reader :root, :backend, :handle

    def initialize(root, backend: Backends::ThreeJS.new)
      @root = root
      @backend = backend
      @handle = @backend.create_animation_mixer(@backend.sync(root))
    end

    def clip_action(clip, root: nil)
      root_handle = root ? @backend.sync(root) : nil
      handle = @backend.animation_mixer_clip_action(@handle, animation_clip_handle(clip), root_handle)
      AnimationAction.new(handle, backend: @backend)
    end

    def update(delta)
      @backend.update_animation_mixer(@handle, delta)
      self
    end

    def stop_all_action
      @backend.stop_all_animation_actions(@handle)
      self
    end

    def uncache_root(root = @root)
      @backend.uncache_animation_root(@handle, @backend.sync(root))
      self
    end

    private

    def animation_clip_handle(clip)
      clip.respond_to?(:handle) ? clip.handle : clip
    end
  end
end
