# frozen_string_literal: true

require_relative "../materials/sprite_material"
require_relative "../math/vector2"
require_relative "group"

module Three
  class Sprite < Object3D
    attr_reader :material, :center

    def initialize(material = SpriteMaterial.new)
      super()
      @type = "Sprite"
      @material = nil
      @center = Vector2.new(0.5, 0.5)
      bind_center_changes
      self.material = material
    end

    def material=(value)
      @material.remove_dirty_dependent(self) if @material.respond_to?(:remove_dirty_dependent)
      @material = value
      @material.add_dirty_dependent(self) if @material.respond_to?(:add_dirty_dependent)
      mark_dirty!(:sprite)
    end

    def center=(value)
      @center = coerce_center(value)
      bind_center_changes
      mark_dirty!(:sprite)
    end

    def to_h
      super.merge(
        material: @material.respond_to?(:uuid) ? @material.uuid : nil,
        center: @center.to_a
      )
    end

    private

    def coerce_center(value)
      return value if value.is_a?(Vector2)

      if value.respond_to?(:to_a)
        array = value.to_a
        return Vector2.new(array[0], array[1]) if array.length == 2
      end

      raise TypeError, "center must be a Three::Vector2 or an array-like [x, y]"
    end

    def bind_center_changes
      @center.on_change { mark_dirty!(:sprite) }
    end
  end
end
