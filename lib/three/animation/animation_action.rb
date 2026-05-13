# frozen_string_literal: true

module Three
  class AnimationAction
    PROPERTY_NAMES = {
      enabled: "enabled",
      paused: "paused",
      time: "time",
      time_scale: "timeScale",
      weight: "weight",
      loop: "loop",
      repetitions: "repetitions",
      clamp_when_finished: "clampWhenFinished"
    }.freeze

    attr_reader :handle, :backend
    attr_reader(*PROPERTY_NAMES.keys)

    def initialize(handle, backend:)
      @handle = handle
      @backend = backend
    end

    def play
      @backend.play_animation_action(@handle)
      self
    end

    def stop
      @backend.stop_animation_action(@handle)
      self
    end

    def reset
      @backend.reset_animation_action(@handle)
      self
    end

    def fade_in(duration)
      @backend.fade_in_animation_action(@handle, duration)
      self
    end

    def fade_out(duration)
      @backend.fade_out_animation_action(@handle, duration)
      self
    end

    PROPERTY_NAMES.each do |ruby_name, js_name|
      define_method("#{ruby_name}=") do |value|
        instance_variable_set("@#{ruby_name}", value)
        @backend.set_animation_action_property(@handle, js_name, value)
        value
      end
    end
  end
end
