# frozen_string_literal: true

require_relative "../core/event_dispatcher"
require_relative "../constants"
require_relative "../dirty"
require_relative "../math/math_utils"
require_relative "../math/vector2"

module Three
  class Texture < EventDispatcher
    include Dirty

    @next_id = 0

    class << self
      attr_accessor :next_id
    end

    attr_reader :id, :uuid, :source, :flip_y, :wrap_s, :wrap_t, :mag_filter, :min_filter, :repeat
    attr_accessor :user_data

    def initialize(source = nil, flip_y: true, wrap_s: Three::ClampToEdgeWrapping, wrap_t: Three::ClampToEdgeWrapping, mag_filter: Three::LinearFilter, min_filter: Three::LinearMipmapLinearFilter, repeat: nil)
      super()
      @id = self.class.allocate_id
      @uuid = MathUtils.generate_uuid
      @source = source
      @flip_y = flip_y
      @wrap_s = wrap_s
      @wrap_t = wrap_t
      @mag_filter = mag_filter
      @min_filter = min_filter
      @repeat = coerce_vector2(repeat || [1, 1])
      @user_data = {}
      bind_repeat_changes
      mark_dirty!
    end

    def source=(value)
      @source = value
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
      @repeat = coerce_vector2(value)
      bind_repeat_changes
      mark_dirty!(:parameters)
    end

    def dispose
      dispatch_event(:dispose)
    end

    def to_h
      {
        uuid: @uuid,
        type: "Texture",
        source: @source,
        flip_y: @flip_y,
        wrap_s: @wrap_s,
        wrap_t: @wrap_t,
        mag_filter: @mag_filter,
        min_filter: @min_filter,
        repeat: @repeat.to_a
      }
    end

    def self.allocate_id
      id = Texture.next_id
      Texture.next_id += 1
      id
    end

    private

    def coerce_vector2(value)
      return value if value.is_a?(Vector2)

      array = value.to_ary if value.respond_to?(:to_ary)
      array ||= value.to_a if value.respond_to?(:to_a)
      return Vector2.new(array[0], array[1]) if array && array.length >= 2

      raise TypeError, "repeat must be a Three::Vector2 or an array-like [x, y]"
    end

    def bind_repeat_changes
      @repeat.on_change { mark_dirty!(:parameters) }
    end
  end
end
