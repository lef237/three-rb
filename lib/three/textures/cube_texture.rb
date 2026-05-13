# frozen_string_literal: true

require_relative "texture"

module Three
  class CubeTexture < Texture
    FACE_COUNT = 6

    def initialize(
      sources,
      mapping: Three::CubeReflectionMapping,
      color_space: Three::NoColorSpace,
      flip_y: false,
      wrap_s: Three::ClampToEdgeWrapping,
      wrap_t: Three::ClampToEdgeWrapping,
      mag_filter: Three::LinearFilter,
      min_filter: Three::LinearMipmapLinearFilter,
      offset: nil,
      repeat: nil,
      center: nil,
      rotation: 0,
      matrix_auto_update: true,
      matrix: nil
    )
      super(
        validate_sources(sources),
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

    def sources
      source
    end

    def sources=(value)
      self.source = value
    end

    def source=(value)
      super(validate_sources(value))
    end

    def to_h
      super.merge(type: "CubeTexture", sources: sources)
    end

    private

    def validate_sources(value)
      array = value.to_ary if value.respond_to?(:to_ary)
      array ||= value.to_a if value.respond_to?(:to_a)

      unless array&.length == FACE_COUNT
        raise ArgumentError, "cube texture sources must contain six image sources"
      end

      array.dup
    end
  end
end
