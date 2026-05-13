# frozen_string_literal: true

require_relative "../core/buffer_attribute"
require_relative "../core/buffer_geometry"

module Three
  class PlaneGeometry < BufferGeometry
    attr_accessor :parameters

    def initialize(width = 1, height = 1, width_segments: 1, height_segments: 1)
      super()
      @type = "PlaneGeometry"
      @parameters = {
        width: width,
        height: height,
        width_segments: width_segments,
        height_segments: height_segments
      }

      build(width, height, width_segments.floor, height_segments.floor)
    end

    private

    # Plane construction follows three.js PlaneGeometry's MIT-licensed algorithm.
    def build(width, height, width_segments, height_segments)
      width_half = width / 2.0
      height_half = height / 2.0
      grid_x = width_segments
      grid_y = height_segments
      grid_x1 = grid_x + 1
      grid_y1 = grid_y + 1
      segment_width = width.to_f / grid_x
      segment_height = height.to_f / grid_y

      indices = []
      vertices = []
      normals = []
      uvs = []

      grid_y1.times do |iy|
        y = iy * segment_height - height_half

        grid_x1.times do |ix|
          x = ix * segment_width - width_half

          vertices.push(x, -y, 0)
          normals.push(0, 0, 1)
          uvs.push(ix.to_f / grid_x, 1 - (iy.to_f / grid_y))
        end
      end

      grid_y.times do |iy|
        grid_x.times do |ix|
          a = ix + grid_x1 * iy
          b = ix + grid_x1 * (iy + 1)
          c = (ix + 1) + grid_x1 * (iy + 1)
          d = (ix + 1) + grid_x1 * iy

          indices.push(a, b, d, b, c, d)
        end
      end

      set_index(indices)
      set_attribute(:position, Float32BufferAttribute.new(vertices, 3))
      set_attribute(:normal, Float32BufferAttribute.new(normals, 3))
      set_attribute(:uv, Float32BufferAttribute.new(uvs, 2))
    end
  end
end
