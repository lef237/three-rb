# frozen_string_literal: true

require_relative "../math/color"
require_relative "material"

module Three
  class MeshBasicMaterial < Material
    attr_accessor :color, :wireframe, :wireframe_linewidth, :fog

    def initialize(parameters = nil)
      super(nil)
      @type = "MeshBasicMaterial"
      @color = Color.new(0xffffff)
      @wireframe = false
      @wireframe_linewidth = 1
      @fog = true
      set_values(parameters) if parameters
    end

    def to_h
      super.merge(
        color: @color.hex,
        wireframe: @wireframe,
        wireframe_linewidth: @wireframe_linewidth,
        fog: @fog
      )
    end
  end
end
