# frozen_string_literal: true

require_relative "../backends/threejs"

module Three
  class AnimationClip
    attr_reader :handle, :adapter

    def initialize(handle, adapter: Backends::ThreeJS::RubyWasmAdapter.new)
      @handle = handle
      @adapter = adapter
    end

    def name
      @adapter.animation_clip_name(@handle)
    end

    def duration
      @adapter.animation_clip_duration(@handle)
    end
  end
end
