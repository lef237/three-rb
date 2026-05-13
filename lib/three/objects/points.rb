# frozen_string_literal: true

require_relative "../core/buffer_geometry"
require_relative "../materials/points_material"
require_relative "group"

module Three
  class Points < Object3D
    attr_reader :geometry, :material

    def initialize(geometry = BufferGeometry.new, material = PointsMaterial.new)
      super()
      @type = "Points"
      @geometry = nil
      @material = nil
      self.geometry = geometry
      self.material = material
    end

    def geometry=(value)
      @geometry.remove_dirty_dependent(self) if @geometry.respond_to?(:remove_dirty_dependent)
      @geometry = value
      @geometry.add_dirty_dependent(self) if @geometry.respond_to?(:add_dirty_dependent)
      mark_dirty!(:points)
    end

    def material=(value)
      @material.remove_dirty_dependent(self) if @material.respond_to?(:remove_dirty_dependent)
      @material = value
      @material.add_dirty_dependent(self) if @material.respond_to?(:add_dirty_dependent)
      mark_dirty!(:points)
    end

    def to_h
      super.merge(
        geometry: @geometry.uuid,
        material: @material.respond_to?(:uuid) ? @material.uuid : nil
      )
    end
  end
end
