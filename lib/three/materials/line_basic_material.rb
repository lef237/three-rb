# frozen_string_literal: true

require_relative "../math/color"
require_relative "material"

module Three
  class LineBasicMaterial < Material
    attr_reader :color, :linewidth, :linecap, :linejoin, :fog

    def initialize(parameters = nil)
      super(nil)
      @type = "LineBasicMaterial"
      @color = Color.new(0xffffff)
      @linewidth = 1
      @linecap = "round"
      @linejoin = "round"
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

    def linewidth=(value)
      @linewidth = value
      mark_dirty!(:parameters)
    end

    def linecap=(value)
      @linecap = value
      mark_dirty!(:parameters)
    end

    def linejoin=(value)
      @linejoin = value
      mark_dirty!(:parameters)
    end

    def fog=(value)
      @fog = value
      mark_dirty!(:parameters)
    end

    def to_h
      super.merge(
        color: @color.hex,
        linewidth: @linewidth,
        linecap: @linecap,
        linejoin: @linejoin,
        fog: @fog
      )
    end

    private

    def bind_color_changes
      @color.on_change { mark_dirty!(:parameters) }
    end
  end
end
