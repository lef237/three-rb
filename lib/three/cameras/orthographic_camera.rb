# frozen_string_literal: true

require_relative "camera"

module Three
  class OrthographicCamera < Camera
    attr_reader :left, :right, :top, :bottom, :near, :far, :zoom
    attr_reader :view

    def initialize(left = -1, right = 1, top = 1, bottom = -1, near: 0.1, far: 2000)
      super()
      @type = "OrthographicCamera"
      @left = left
      @right = right
      @top = top
      @bottom = bottom
      @near = near
      @far = far
      @zoom = 1
      @view = nil
      update_projection_matrix
    end

    def left=(value)
      @left = value
      mark_dirty!(:camera)
    end

    def right=(value)
      @right = value
      mark_dirty!(:camera)
    end

    def top=(value)
      @top = value
      mark_dirty!(:camera)
    end

    def bottom=(value)
      @bottom = value
      mark_dirty!(:camera)
    end

    def near=(value)
      @near = value
      mark_dirty!(:camera)
    end

    def far=(value)
      @far = value
      mark_dirty!(:camera)
    end

    def zoom=(value)
      @zoom = value
      mark_dirty!(:camera)
    end

    def set_view_offset(full_width, full_height, x, y, width, height)
      @view = {
        enabled: true,
        full_width: full_width,
        full_height: full_height,
        offset_x: x,
        offset_y: y,
        width: width,
        height: height
      }
      mark_dirty!(:camera)
      update_projection_matrix
      self
    end

    def clear_view_offset
      @view[:enabled] = false if @view
      mark_dirty!(:camera)
      update_projection_matrix
      self
    end

    def update_projection_matrix
      dx = (@right - @left).to_f / (2 * @zoom)
      dy = (@top - @bottom).to_f / (2 * @zoom)
      cx = (@right + @left).to_f / 2
      cy = (@top + @bottom).to_f / 2

      left = cx - dx
      right = cx + dx
      top = cy + dy
      bottom = cy - dy

      if @view && @view[:enabled]
        scale_w = (@right - @left).to_f / @view[:full_width] / @zoom
        scale_h = (@top - @bottom).to_f / @view[:full_height] / @zoom
        left += scale_w * @view[:offset_x]
        right = left + scale_w * @view[:width]
        top -= scale_h * @view[:offset_y]
        bottom = top - scale_h * @view[:height]
      end

      @projection_matrix.make_orthographic(left, right, top, bottom, @near, @far)
      @projection_matrix_inverse.copy(@projection_matrix).invert
      mark_dirty!(:camera)
      self
    end
  end
end
