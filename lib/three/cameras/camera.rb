# frozen_string_literal: true

require_relative "../core/object3d"

module Three
  class Camera < Object3D
    attr_reader :matrix_world_inverse, :projection_matrix, :projection_matrix_inverse

    def initialize
      super
      @type = "Camera"
      @matrix_world_inverse = Matrix4.new
      @projection_matrix = Matrix4.new
      @projection_matrix_inverse = Matrix4.new
    end

    def update_matrix_world(force = false)
      super
      update_matrix_world_inverse
      self
    end

    def update_world_matrix(update_parents = false, update_children = false)
      super
      update_matrix_world_inverse
      self
    end

    def get_world_direction(target = Vector3.new)
      super(target).negate
    end

    private

    def update_matrix_world_inverse
      @matrix_world_inverse.copy(@matrix_world).invert
    end
  end
end
