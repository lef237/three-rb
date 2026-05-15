# frozen_string_literal: true

require_relative "../core/buffer_geometry"

module Three
  class TextGeometry < BufferGeometry
    attr_reader :text, :parameters

    def initialize(
      text,
      font:,
      size: 1,
      depth: 0.2,
      curve_segments: 12,
      steps: 1,
      bevel_enabled: false,
      bevel_thickness: 0.01,
      bevel_size: 0.01,
      bevel_offset: 0,
      bevel_segments: 3,
      direction: "ltr"
    )
      super()
      @type = "TextGeometry"
      @text = text.to_s
      @parameters = {
        font: font,
        size: size,
        depth: depth,
        curve_segments: curve_segments,
        steps: steps,
        bevel_enabled: bevel_enabled,
        bevel_thickness: bevel_thickness,
        bevel_size: bevel_size,
        bevel_offset: bevel_offset,
        bevel_segments: bevel_segments,
        direction: direction
      }
    end
  end
end
