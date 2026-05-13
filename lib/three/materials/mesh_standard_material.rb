# frozen_string_literal: true

require_relative "../math/color"
require_relative "material"

module Three
  class MeshStandardMaterial < Material
    attr_reader :color, :roughness, :metalness, :wireframe, :wireframe_linewidth, :fog, :flat_shading, :map

    def initialize(parameters = nil)
      super(nil)
      @type = "MeshStandardMaterial"
      @color = Color.new(0xffffff)
      @roughness = 1
      @metalness = 0
      @map = nil
      @wireframe = false
      @wireframe_linewidth = 1
      @fog = true
      @flat_shading = false
      bind_color_changes
      set_values(parameters) if parameters
      mark_dirty!
    end

    def color=(value)
      @color = value.is_a?(Color) ? value : Color.new(value)
      bind_color_changes
      mark_dirty!(:parameters)
    end

    def roughness=(value)
      @roughness = value
      mark_dirty!(:parameters)
    end

    def metalness=(value)
      @metalness = value
      mark_dirty!(:parameters)
    end

    def map=(value)
      @map = value
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

    def flat_shading=(value)
      @flat_shading = value
      mark_dirty!(:parameters)
    end

    def to_h
      super.merge(
        color: @color.hex,
        roughness: @roughness,
        metalness: @metalness,
        map: @map&.to_h,
        wireframe: @wireframe,
        wireframe_linewidth: @wireframe_linewidth,
        fog: @fog,
        flat_shading: @flat_shading
      )
    end

    private

    def bind_color_changes
      @color.on_change { mark_dirty!(:parameters) }
    end
  end
end
