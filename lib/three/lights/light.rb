# frozen_string_literal: true

require_relative "../core/object3d"
require_relative "../math/color"

module Three
  class Light < Object3D
    attr_reader :color, :intensity
    attr_reader :shadow_map_size, :shadow_bias, :shadow_normal_bias, :shadow_radius

    def initialize(color = 0xffffff, intensity = 1)
      super()
      @type = "Light"
      @color = Color.new(color)
      @intensity = intensity
      @shadow_map_size = [512, 512]
      @shadow_bias = 0
      @shadow_normal_bias = 0
      @shadow_radius = 1
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

    def shadow_map_size=(value)
      array = coerce_shadow_map_size(value)
      @shadow_map_size = array
      mark_dirty!(:shadow)
    end

    def shadow_bias=(value)
      @shadow_bias = value
      mark_dirty!(:shadow)
    end

    def shadow_normal_bias=(value)
      @shadow_normal_bias = value
      mark_dirty!(:shadow)
    end

    def shadow_radius=(value)
      @shadow_radius = value
      mark_dirty!(:shadow)
    end

    def dispose
      dispatch_event(:dispose)
    end

    def to_h
      super.merge(
        color: @color.hex,
        intensity: @intensity,
        shadow_map_size: @shadow_map_size.dup,
        shadow_bias: @shadow_bias,
        shadow_normal_bias: @shadow_normal_bias,
        shadow_radius: @shadow_radius
      )
    end

    private

    def bind_color_changes
      @color.on_change { mark_dirty!(:light) }
    end

    def coerce_shadow_map_size(value)
      array = value.to_ary if value.respond_to?(:to_ary)
      array ||= value.to_a if value.respond_to?(:to_a)
      raise TypeError, "shadow_map_size must be array-like [width, height]" unless array && array.length >= 2

      [array[0], array[1]]
    end
  end
end
