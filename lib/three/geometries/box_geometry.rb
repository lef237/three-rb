# frozen_string_literal: true

require_relative "../core/buffer_attribute"
require_relative "../core/buffer_geometry"

module Three
  class BoxGeometry < BufferGeometry
    attr_accessor :parameters

    def initialize(width = 1, height = 1, depth = 1, width_segments: 1, height_segments: 1, depth_segments: 1)
      super()
      @type = "BoxGeometry"
      @parameters = {
        width: width,
        height: height,
        depth: depth,
        width_segments: width_segments,
        height_segments: height_segments,
        depth_segments: depth_segments
      }

      build(width, height, depth, width_segments.floor, height_segments.floor, depth_segments.floor)
    end

    private

    def build(width, height, depth, width_segments, height_segments, depth_segments)
      indices = []
      vertices = []
      normals = []
      uvs = []
      state = { vertex_count: 0, group_start: 0 }

      build_plane(indices, vertices, normals, uvs, state, "z", "y", "x", -1, -1, depth, height, width, depth_segments, height_segments, 0)
      build_plane(indices, vertices, normals, uvs, state, "z", "y", "x", 1, -1, depth, height, -width, depth_segments, height_segments, 1)
      build_plane(indices, vertices, normals, uvs, state, "x", "z", "y", 1, 1, width, depth, height, width_segments, depth_segments, 2)
      build_plane(indices, vertices, normals, uvs, state, "x", "z", "y", 1, -1, width, depth, -height, width_segments, depth_segments, 3)
      build_plane(indices, vertices, normals, uvs, state, "x", "y", "z", 1, -1, width, height, depth, width_segments, height_segments, 4)
      build_plane(indices, vertices, normals, uvs, state, "x", "y", "z", -1, -1, width, height, -depth, width_segments, height_segments, 5)

      set_index(indices)
      set_attribute(:position, Float32BufferAttribute.new(vertices, 3))
      set_attribute(:normal, Float32BufferAttribute.new(normals, 3))
      set_attribute(:uv, Float32BufferAttribute.new(uvs, 2))
    end

    # Plane construction follows three.js BoxGeometry's MIT-licensed algorithm.
    def build_plane(indices, vertices, normals, uvs, state, u, v, w, udir, vdir, width, height, depth, grid_x, grid_y, material_index)
      segment_width = width.to_f / grid_x
      segment_height = height.to_f / grid_y
      width_half = width / 2.0
      height_half = height / 2.0
      depth_half = depth / 2.0
      grid_x1 = grid_x + 1
      grid_y1 = grid_y + 1
      vertex_counter = 0
      group_count = 0

      grid_y1.times do |iy|
        y = iy * segment_height - height_half

        grid_x1.times do |ix|
          x = ix * segment_width - width_half
          vector = { "x" => 0, "y" => 0, "z" => 0 }
          vector[u] = x * udir
          vector[v] = y * vdir
          vector[w] = depth_half
          vertices.push(vector["x"], vector["y"], vector["z"])

          vector[u] = 0
          vector[v] = 0
          vector[w] = depth.positive? ? 1 : -1
          normals.push(vector["x"], vector["y"], vector["z"])

          uvs.push(ix.to_f / grid_x, 1 - (iy.to_f / grid_y))
          vertex_counter += 1
        end
      end

      grid_y.times do |iy|
        grid_x.times do |ix|
          a = state[:vertex_count] + ix + grid_x1 * iy
          b = state[:vertex_count] + ix + grid_x1 * (iy + 1)
          c = state[:vertex_count] + (ix + 1) + grid_x1 * (iy + 1)
          d = state[:vertex_count] + (ix + 1) + grid_x1 * iy

          indices.push(a, b, d, b, c, d)
          group_count += 6
        end
      end

      add_group(state[:group_start], group_count, material_index)
      state[:group_start] += group_count
      state[:vertex_count] += vertex_counter
    end
  end
end
