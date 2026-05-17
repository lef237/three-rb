# frozen_string_literal: true

require_relative "../core/event_dispatcher"
require_relative "../constants"
require_relative "../dirty"
require_relative "../math/math_utils"
require_relative "../math/matrix3"
require_relative "../math/vector2"

module Three
  class Texture < EventDispatcher
    include Dirty

    @next_id = 0

    class << self
      attr_accessor :next_id
    end

    attr_reader :id, :uuid, :source, :mapping, :color_space, :flip_y, :wrap_s, :wrap_t, :mag_filter, :min_filter
    attr_reader :offset, :repeat, :center, :rotation, :matrix_auto_update, :matrix
    attr_accessor :user_data

    def initialize(
      source = nil,
      mapping: Three::UVMapping,
      color_space: Three::NoColorSpace,
      flip_y: true,
      wrap_s: Three::ClampToEdgeWrapping,
      wrap_t: Three::ClampToEdgeWrapping,
      mag_filter: Three::LinearFilter,
      min_filter: Three::LinearMipmapLinearFilter,
      offset: nil,
      repeat: nil,
      center: nil,
      rotation: 0,
      matrix_auto_update: true,
      matrix: nil
    )
      super()
      @id = self.class.allocate_id
      @uuid = MathUtils.generate_uuid
      @source = source
      @mapping = mapping
      @color_space = color_space
      @flip_y = flip_y
      @wrap_s = wrap_s
      @wrap_t = wrap_t
      @mag_filter = mag_filter
      @min_filter = min_filter
      @offset = coerce_vector2(offset || [0, 0], field: :offset)
      @repeat = coerce_vector2(repeat || [1, 1], field: :repeat)
      @center = coerce_vector2(center || [0, 0], field: :center)
      @rotation = rotation
      @matrix_auto_update = matrix_auto_update
      @matrix = coerce_matrix3(matrix || Matrix3.new)
      @user_data = {}
      bind_vector_changes
      mark_dirty!
    end

    def source=(value)
      @source = value
      mark_dirty!(:parameters)
    end

    def mapping=(value)
      @mapping = value
      mark_dirty!(:parameters)
    end

    def color_space=(value)
      @color_space = value
      mark_dirty!(:parameters)
    end

    def flip_y=(value)
      @flip_y = value
      mark_dirty!(:parameters)
    end

    def wrap_s=(value)
      @wrap_s = value
      mark_dirty!(:parameters)
    end

    def wrap_t=(value)
      @wrap_t = value
      mark_dirty!(:parameters)
    end

    def mag_filter=(value)
      @mag_filter = value
      mark_dirty!(:parameters)
    end

    def min_filter=(value)
      @min_filter = value
      mark_dirty!(:parameters)
    end

    def repeat=(value)
      @repeat = coerce_vector2(value, field: :repeat)
      bind_vector_changes
      mark_dirty!(:parameters)
    end

    def offset=(value)
      @offset = coerce_vector2(value, field: :offset)
      bind_vector_changes
      mark_dirty!(:parameters)
    end

    def center=(value)
      @center = coerce_vector2(value, field: :center)
      bind_vector_changes
      mark_dirty!(:parameters)
    end

    def rotation=(value)
      @rotation = value
      mark_dirty!(:parameters)
    end

    def matrix_auto_update=(value)
      @matrix_auto_update = value
      mark_dirty!(:parameters)
    end

    def matrix=(value)
      @matrix = coerce_matrix3(value)
      mark_dirty!(:parameters)
    end

    def update_matrix
      @matrix.set_uv_transform(@offset.x, @offset.y, @repeat.x, @repeat.y, @rotation, @center.x, @center.y)
      mark_dirty!(:parameters)
      self
    end

    def dispose
      dispatch_event(:dispose)
    end

    def to_h
      {
        uuid: @uuid,
        type: "Texture",
        source: @source,
        mapping: @mapping,
        color_space: @color_space,
        flip_y: @flip_y,
        wrap_s: @wrap_s,
        wrap_t: @wrap_t,
        mag_filter: @mag_filter,
        min_filter: @min_filter,
        offset: @offset.to_a,
        repeat: @repeat.to_a,
        center: @center.to_a,
        rotation: @rotation,
        matrix_auto_update: @matrix_auto_update,
        matrix: @matrix.to_a,
        user_data: @user_data
      }
    end

    def self.allocate_id
      id = Texture.next_id
      Texture.next_id += 1
      id
    end

    private

    def coerce_vector2(value, field:)
      return value if value.is_a?(Vector2)

      array = value.to_ary if value.respond_to?(:to_ary)
      array ||= value.to_a if value.respond_to?(:to_a)
      return Vector2.new(array[0], array[1]) if array && array.length >= 2

      raise TypeError, "#{field} must be a Three::Vector2 or an array-like [x, y]"
    end

    def coerce_matrix3(value)
      return value if value.is_a?(Matrix3)

      array = value.to_ary if value.respond_to?(:to_ary)
      array ||= value.to_a if value.respond_to?(:to_a)
      return Matrix3.new.from_array(array) if array && array.length >= 9

      raise TypeError, "matrix must be a Three::Matrix3 or an array-like with 9 elements"
    end

    def bind_vector_changes
      @offset.on_change { mark_dirty!(:parameters) }
      @repeat.on_change { mark_dirty!(:parameters) }
      @center.on_change { mark_dirty!(:parameters) }
    end
  end
end
