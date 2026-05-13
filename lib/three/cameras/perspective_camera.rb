# frozen_string_literal: true

require_relative "../math/math_utils"
require_relative "camera"

module Three
  class PerspectiveCamera < Camera
    attr_accessor :fov, :zoom, :near, :far, :focus, :aspect, :film_gauge, :film_offset
    attr_reader :view

    def initialize(fov = 50, aspect: 1, near: 0.1, far: 2000)
      super()
      @type = "PerspectiveCamera"
      @fov = fov
      @zoom = 1
      @near = near
      @far = far
      @focus = 10
      @aspect = aspect
      @view = nil
      @film_gauge = 35
      @film_offset = 0
      update_projection_matrix
    end

    def set_focal_length(focal_length)
      vertical_extent_slope = 0.5 * film_height / focal_length
      @fov = MathUtils.rad_to_deg(2 * Math.atan(vertical_extent_slope))
      update_projection_matrix
      self
    end

    def focal_length
      vertical_extent_slope = Math.tan(MathUtils.deg_to_rad(0.5 * @fov))
      0.5 * film_height / vertical_extent_slope
    end

    def effective_fov
      MathUtils.rad_to_deg(2 * Math.atan(Math.tan(MathUtils.deg_to_rad(0.5 * @fov)) / @zoom))
    end

    def film_width
      @film_gauge * [@aspect, 1].min
    end

    def film_height
      @film_gauge / [@aspect, 1].max
    end

    def set_view_offset(full_width, full_height, x, y, width, height)
      @aspect = full_width.to_f / full_height
      @view = {
        enabled: true,
        full_width: full_width,
        full_height: full_height,
        offset_x: x,
        offset_y: y,
        width: width,
        height: height
      }
      update_projection_matrix
      self
    end

    def clear_view_offset
      @view[:enabled] = false if @view
      update_projection_matrix
      self
    end

    def update_projection_matrix
      top = @near * Math.tan(MathUtils.deg_to_rad(0.5 * @fov)) / @zoom
      height = 2 * top
      width = @aspect * height
      left = -0.5 * width

      if @view && @view[:enabled]
        full_width = @view[:full_width]
        full_height = @view[:full_height]
        left += @view[:offset_x] * width / full_width
        top -= @view[:offset_y] * height / full_height
        width *= @view[:width].to_f / full_width
        height *= @view[:height].to_f / full_height
      end

      left += @near * @film_offset / film_width unless @film_offset.zero?

      @projection_matrix.make_perspective(left, left + width, top, top - height, @near, @far)
      @projection_matrix_inverse.copy(@projection_matrix).invert
      self
    end
  end
end
