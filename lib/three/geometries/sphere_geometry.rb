# frozen_string_literal: true

require_relative "../core/buffer_attribute"
require_relative "../core/buffer_geometry"

module Three
  class SphereGeometry < BufferGeometry
    attr_accessor :parameters

    def initialize(radius = 1, width_segments: 32, height_segments: 16, phi_start: 0, phi_length: Math::PI * 2, theta_start: 0, theta_length: Math::PI)
      super()
      @type = "SphereGeometry"
      @parameters = {
        radius: radius,
        width_segments: width_segments,
        height_segments: height_segments,
        phi_start: phi_start,
        phi_length: phi_length,
        theta_start: theta_start,
        theta_length: theta_length
      }

      build(
        radius,
        [3, width_segments.floor].max,
        [2, height_segments.floor].max,
        phi_start,
        phi_length,
        theta_start,
        theta_length
      )
    end

    private

    # Sphere construction follows three.js SphereGeometry's MIT-licensed algorithm.
    def build(radius, width_segments, height_segments, phi_start, phi_length, theta_start, theta_length)
      theta_end = [theta_start + theta_length, Math::PI].min
      index = 0
      grid = []
      indices = []
      vertices = []
      normals = []
      uvs = []

      (height_segments + 1).times do |iy|
        vertices_row = []
        v = iy.to_f / height_segments
        u_offset = uv_offset(iy, height_segments, width_segments, theta_start, theta_end)

        (width_segments + 1).times do |ix|
          u = ix.to_f / width_segments
          theta = theta_start + v * theta_length
          phi = phi_start + u * phi_length

          x = -radius * Math.cos(phi) * Math.sin(theta)
          y = radius * Math.cos(theta)
          z = radius * Math.sin(phi) * Math.sin(theta)

          vertices.push(x, y, z)
          push_normal(normals, x, y, z)
          uvs.push(u + u_offset, 1 - v)
          vertices_row << index
          index += 1
        end

        grid << vertices_row
      end

      height_segments.times do |iy|
        width_segments.times do |ix|
          a = grid[iy][ix + 1]
          b = grid[iy][ix]
          c = grid[iy + 1][ix]
          d = grid[iy + 1][ix + 1]

          indices.push(a, b, d) if iy != 0 || theta_start.positive?
          indices.push(b, c, d) if iy != height_segments - 1 || theta_end < Math::PI
        end
      end

      set_index(indices)
      set_attribute(:position, Float32BufferAttribute.new(vertices, 3))
      set_attribute(:normal, Float32BufferAttribute.new(normals, 3))
      set_attribute(:uv, Float32BufferAttribute.new(uvs, 2))
    end

    def uv_offset(iy, height_segments, width_segments, theta_start, theta_end)
      if iy.zero? && theta_start.zero?
        0.5 / width_segments
      elsif iy == height_segments && theta_end == Math::PI
        -0.5 / width_segments
      else
        0
      end
    end

    def push_normal(normals, x, y, z)
      length = Math.sqrt((x * x) + (y * y) + (z * z))
      if length.zero?
        normals.push(0, 0, 0)
      else
        normals.push(x / length, y / length, z / length)
      end
    end
  end
end
