# frozen_string_literal: true

require_relative "../core/object3d"
require_relative "../math/color"

module Three
  class Light < Object3D
    attr_reader :color, :intensity

    def initialize(color = 0xffffff, intensity = 1)
      super()
      @type = "Light"
      @color = Color.new(color)
      @intensity = intensity
      bind_color_changes
      mark_dirty!(:light)
    end

    def color=(value)
      @color = value.is_a?(Color) ? value : Color.new(value)
      bind_color_changes
      mark_dirty!(:light)
    end

    def intensity=(value)
      @intensity = value
      mark_dirty!(:light)
    end

    def dispose
      dispatch_event(:dispose)
    end

    def to_h
      super.merge(
        color: @color.hex,
        intensity: @intensity
      )
    end

    private

    def bind_color_changes
      @color.on_change { mark_dirty!(:light) }
    end
  end
end
