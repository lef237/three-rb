# frozen_string_literal: true

require_relative "../math/color"
require_relative "material"

module Three
  class SpriteMaterial < Material
    attr_reader :color, :map, :alpha_map, :rotation, :size_attenuation, :fog

    def initialize(parameters = nil)
      super(nil)
      @type = "SpriteMaterial"
      @color = Color.new(0xffffff)
      @map = nil
      @alpha_map = nil
      @rotation = 0
      @size_attenuation = true
      @transparent = true
      @fog = true
      bind_color_changes
      set_values(parameters) if parameters
      mark_dirty!
    end

    def color=(value)
      @color = value.is_a?(Color) ? value : Color.new(value)
      bind_color_changes
      mark_dirty!(:parameters)
    end

    def map=(value)
      replace_texture_slot(:map, value)
    end

    def alpha_map=(value)
      replace_texture_slot(:alpha_map, value)
    end

    def rotation=(value)
      @rotation = value
      mark_dirty!(:parameters)
    end

    def size_attenuation=(value)
      @size_attenuation = value
      mark_dirty!(:parameters)
    end

    def fog=(value)
      @fog = value
      mark_dirty!(:parameters)
    end

    def texture_slots
      %i[map alpha_map]
    end

    def to_h
      super.merge(
        color: @color.hex,
        map: @map&.to_h,
        alpha_map: @alpha_map&.to_h,
        rotation: @rotation,
        size_attenuation: @size_attenuation,
        fog: @fog
      )
    end

    private

    def bind_color_changes
      @color.on_change { mark_dirty!(:parameters) }
    end
  end
end
