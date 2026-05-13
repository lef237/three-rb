# frozen_string_literal: true

require_relative "texture"

module Three
  class RGBETexture < Texture
    def initialize(
      source,
      mapping: Three::EquirectangularReflectionMapping,
      color_space: Three::LinearSRGBColorSpace,
      flip_y: true,
      wrap_s: Three::ClampToEdgeWrapping,
      wrap_t: Three::ClampToEdgeWrapping,
      mag_filter: Three::LinearFilter,
      min_filter: Three::LinearFilter,
      offset: nil,
      repeat: nil,
      center: nil,
      rotation: 0,
      matrix_auto_update: true,
      matrix: nil
    )
      super(
        source,
        mapping: mapping,
        color_space: color_space,
        flip_y: flip_y,
        wrap_s: wrap_s,
        wrap_t: wrap_t,
        mag_filter: mag_filter,
        min_filter: min_filter,
        offset: offset,
        repeat: repeat,
        center: center,
        rotation: rotation,
        matrix_auto_update: matrix_auto_update,
        matrix: matrix
      )
    end

    def to_h
      super.merge(type: "RGBETexture")
    end
  end
end
