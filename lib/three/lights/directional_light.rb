# frozen_string_literal: true

require_relative "light"

module Three
  class DirectionalLight < Light
    attr_reader :shadow_camera

    def initialize(color = 0xffffff, intensity = 1)
      super
      @type = "DirectionalLight"
      @position.copy(Object3D::DEFAULT_UP)
      @shadow_camera = {
        left: -5,
        right: 5,
        top: 5,
        bottom: -5,
        near: 0.5,
        far: 500
      }
    end

    def set_shadow_camera(left: nil, right: nil, top: nil, bottom: nil, near: nil, far: nil)
      @shadow_camera[:left] = left unless left.nil?
      @shadow_camera[:right] = right unless right.nil?
      @shadow_camera[:top] = top unless top.nil?
      @shadow_camera[:bottom] = bottom unless bottom.nil?
      @shadow_camera[:near] = near unless near.nil?
      @shadow_camera[:far] = far unless far.nil?
      mark_dirty!(:shadow)
      self
    end

    def to_h
      super.merge(shadow_camera: @shadow_camera.dup)
    end
  end
end
