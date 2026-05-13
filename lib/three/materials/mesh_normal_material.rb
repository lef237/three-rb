# frozen_string_literal: true

require_relative "material"

module Three
  class MeshNormalMaterial < Material
    attr_reader :wireframe, :wireframe_linewidth, :flat_shading

    def initialize(parameters = nil)
      super(nil)
      @type = "MeshNormalMaterial"
      @wireframe = false
      @wireframe_linewidth = 1
      @flat_shading = false
      set_values(parameters) if parameters
      mark_dirty!
    end

    def wireframe=(value)
      @wireframe = value
      mark_dirty!(:parameters)
    end

    def wireframe_linewidth=(value)
      @wireframe_linewidth = value
      mark_dirty!(:parameters)
    end

    def flat_shading=(value)
      @flat_shading = value
      mark_dirty!(:parameters)
    end

    def to_h
      super.merge(
        wireframe: @wireframe,
        wireframe_linewidth: @wireframe_linewidth,
        flat_shading: @flat_shading
      )
    end
  end
end
