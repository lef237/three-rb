# frozen_string_literal: true

require_relative "../core/buffer_geometry"
require_relative "../materials/mesh_basic_material"
require_relative "../math/matrix4"
require_relative "mesh"

module Three
  class InstancedMesh < Mesh
    attr_reader :count, :capacity, :instance_matrices

    def initialize(geometry = BufferGeometry.new, material = MeshBasicMaterial.new, count = 1)
      super(geometry, material)
      @type = "InstancedMesh"
      @capacity = coerce_count(count)
      @count = @capacity
      @instance_matrices = Array.new(@capacity) { Matrix4.new }
      mark_dirty!(:instances)
    end

    def count=(value)
      integer = coerce_count(value)
      raise ArgumentError, "count cannot exceed capacity" if integer > @capacity

      @count = integer
      mark_dirty!(:mesh)
    end

    def set_matrix_at(index, matrix)
      validate_instance_index(index)
      @instance_matrices[index] = coerce_matrix(matrix)
      mark_dirty!(:instances)
      self
    end

    def get_matrix_at(index, target = Matrix4.new)
      validate_instance_index(index)
      target.copy(@instance_matrices[index])
    end

    def instance_matrix_needs_update!
      mark_dirty!(:instances)
      self
    end

    def to_h
      super.merge(
        count: @count,
        capacity: @capacity,
        instance_matrices: @instance_matrices.map(&:to_a)
      )
    end

    private

    def coerce_count(value)
      integer = Integer(value)
      raise ArgumentError, "count must be non-negative" if integer.negative?

      integer
    end

    def validate_instance_index(index)
      raise IndexError, "instance index #{index} is out of range" unless index.is_a?(Integer) && index >= 0 && index < @capacity
    end

    def coerce_matrix(matrix)
      return matrix.clone if matrix.is_a?(Matrix4)

      array = matrix.to_a if matrix.respond_to?(:to_a)
      raise TypeError, "matrix must be a Three::Matrix4 or 16-element array" unless array&.length == 16

      Matrix4.new.from_array(array)
    end
  end
end
