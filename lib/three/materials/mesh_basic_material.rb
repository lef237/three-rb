# frozen_string_literal: true

require_relative "../math/color"
require_relative "material"

module Three
  class MeshBasicMaterial < Material
    attr_reader :color, :wireframe, :wireframe_linewidth, :fog

    def initialize(parameters = nil)
      super(nil)
      @type = "MeshBasicMaterial"
      @color = Color.new(0xffffff)
      @wireframe = false
      @wireframe_linewidth = 1
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

    def wireframe=(value)
      @wireframe = value
      mark_dirty!(:parameters)
    end

    def wireframe_linewidth=(value)
      @wireframe_linewidth = value
      mark_dirty!(:parameters)
    end

    def fog=(value)
      @fog = value
      mark_dirty!(:parameters)
    end

    def to_h
      super.merge(
        color: @color.hex,
        wireframe: @wireframe,
        wireframe_linewidth: @wireframe_linewidth,
        fog: @fog
      )
    end

    private

    def bind_color_changes
      @color.on_change { mark_dirty!(:parameters) }
    end
  end
end
