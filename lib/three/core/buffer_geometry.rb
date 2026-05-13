# frozen_string_literal: true

require_relative "../math/math_utils"
require_relative "../math/vector3"
require_relative "buffer_attribute"
require_relative "event_dispatcher"

module Three
  class BufferGeometry < EventDispatcher
    @next_id = 0

    class << self
      attr_accessor :next_id
    end

    attr_reader :id, :uuid
    attr_accessor :name, :type, :index, :attributes, :groups, :draw_range
    attr_accessor :bounding_box, :bounding_sphere, :user_data

    def initialize
      super()
      @id = self.class.allocate_id
      @uuid = MathUtils.generate_uuid
      @name = ""
      @type = "BufferGeometry"
      @index = nil
      @attributes = {}
      @groups = []
      @bounding_box = nil
      @bounding_sphere = nil
      @draw_range = { start: 0, count: Float::INFINITY }
      @user_data = {}
    end

    def self.allocate_id
      id = BufferGeometry.next_id
      BufferGeometry.next_id += 1
      id
    end

    def get_index
      @index
    end

    def set_index(index)
      @index =
        if index.is_a?(Array)
          attribute_class = index.any? { |value| value > 65_535 } ? Uint32BufferAttribute : Uint16BufferAttribute
          attribute_class.new(index, 1)
        else
          index
        end
      self
    end

    def get_attribute(name)
      @attributes[name.to_sym]
    end

    def set_attribute(name, attribute)
      @attributes[name.to_sym] = attribute
      self
    end

    def delete_attribute(name)
      @attributes.delete(name.to_sym)
      self
    end

    def has_attribute?(name)
      @attributes.key?(name.to_sym)
    end

    def add_group(start, count, material_index = 0)
      @groups << { start: start, count: count, material_index: material_index }
      self
    end

    def clear_groups
      @groups.clear
      self
    end

    def set_draw_range(start, count)
      @draw_range[:start] = start
      @draw_range[:count] = count
      self
    end

    def compute_bounding_box
      position = get_attribute(:position)
      @bounding_box = nil
      return self unless position && position.count.positive?

      min = Vector3.new(Float::INFINITY, Float::INFINITY, Float::INFINITY)
      max = Vector3.new(-Float::INFINITY, -Float::INFINITY, -Float::INFINITY)

      position.count.times do |index|
        x = position.get_x(index)
        y = position.get_y(index)
        z = position.get_z(index)
        min.x = [min.x, x].min
        min.y = [min.y, y].min
        min.z = [min.z, z].min
        max.x = [max.x, x].max
        max.y = [max.y, y].max
        max.z = [max.z, z].max
      end

      @bounding_box = { min: min, max: max }
      self
    end

    def compute_bounding_sphere
      compute_bounding_box unless @bounding_box
      position = get_attribute(:position)
      @bounding_sphere = nil
      return self unless position && @bounding_box

      center = @bounding_box[:min].clone.add(@bounding_box[:max]).multiply_scalar(0.5)
      max_radius_sq = 0

      position.count.times do |index|
        point = Vector3.new(position.get_x(index), position.get_y(index), position.get_z(index))
        max_radius_sq = [max_radius_sq, center.distance_to_squared(point)].max
      end

      @bounding_sphere = { center: center, radius: Math.sqrt(max_radius_sq) }
      self
    end

    def dispose
      dispatch_event(:dispose)
    end

    def to_h
      {
        uuid: @uuid,
        type: @type,
        index: @index&.to_h,
        attributes: @attributes.transform_values(&:to_h),
        groups: @groups.map(&:dup),
        bounding_box: serialize_bounds(@bounding_box),
        bounding_sphere: serialize_sphere(@bounding_sphere)
      }
    end

    private

    def serialize_bounds(bounds)
      return nil unless bounds

      { min: bounds[:min].to_a, max: bounds[:max].to_a }
    end

    def serialize_sphere(sphere)
      return nil unless sphere

      { center: sphere[:center].to_a, radius: sphere[:radius] }
    end
  end
end
