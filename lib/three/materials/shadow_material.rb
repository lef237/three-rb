# frozen_string_literal: true

require_relative "../math/color"
require_relative "material"

module Three
  class ShadowMaterial < Material
    attr_reader :color, :fog

    def initialize(parameters = nil)
      super(nil)
      @type = "ShadowMaterial"
      @color = Color.new(0x000000)
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

    def fog=(value)
      @fog = value
      mark_dirty!(:parameters)
    end

    def to_h
      super.merge(
        color: @color.hex,
        fog: @fog
      )
    end

    private

    def bind_color_changes
      @color.on_change { mark_dirty!(:parameters) }
    end
  end
end
