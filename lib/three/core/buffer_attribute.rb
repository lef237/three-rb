# frozen_string_literal: true

require_relative "../dirty"
require_relative "event_dispatcher"

module Three
  class BufferAttribute < EventDispatcher
    include Dirty

    @next_id = 0

    class << self
      attr_accessor :next_id
    end

    attr_reader :id
    attr_accessor :name, :array, :item_size, :normalized, :usage, :update_ranges, :version
    attr_accessor :component_type

    def initialize(array, item_size, normalized = false, component_type: :generic)
      super()
      @id = self.class.allocate_id
      @name = ""
      @array = array.dup
      @item_size = item_size
      @normalized = normalized
      @usage = :static_draw
      @update_ranges = []
      @version = 0
      @component_type = component_type
      mark_dirty!
    end

    def self.allocate_id
      id = BufferAttribute.next_id
      BufferAttribute.next_id += 1
      id
    end

    def count
      @array.length / @item_size
    end

    def needs_update=(value)
      return unless value

      needs_update!
    end

    def needs_update!
      @version += 1
      mark_dirty!(:array)
      dispatch_event(:change)
      self
    end

    def set_usage(value)
      @usage = value
      mark_dirty!(:usage)
      self
    end

    def add_update_range(start, count)
      @update_ranges << { start: start, count: count }
      mark_dirty!(:update_ranges)
      self
    end

    def clear_update_ranges
      @update_ranges.clear
      mark_dirty!(:update_ranges)
      self
    end

    def copy(source)
      @name = source.name
      @array = source.array.dup
      @item_size = source.item_size
      @normalized = source.normalized
      @usage = source.usage
      @component_type = source.component_type
      needs_update!
      self
    end

    def clone
      self.class.new(@array, @item_size, @normalized)
    end

    def get_component(index, component)
      @array[index * @item_size + component]
    end

    def set_component(index, component, value)
      @array[index * @item_size + component] = value
      needs_update!
      self
    end

    def get_x(index)
      get_component(index, 0)
    end

    def get_y(index)
      get_component(index, 1)
    end

    def get_z(index)
      get_component(index, 2)
    end

    def set_x(index, value)
      set_component(index, 0, value)
    end

    def set_y(index, value)
      set_component(index, 1, value)
    end

    def set_z(index, value)
      set_component(index, 2, value)
    end

    def to_h
      {
        item_size: @item_size,
        component_type: @component_type,
        normalized: @normalized,
        array: @array.dup
      }
    end
  end

  class Float32BufferAttribute < BufferAttribute
    def initialize(array, item_size, normalized = false)
      super(array, item_size, normalized, component_type: :float32)
    end
  end

  class Uint16BufferAttribute < BufferAttribute
    def initialize(array, item_size, normalized = false)
      super(array, item_size, normalized, component_type: :uint16)
    end
  end

  class Uint32BufferAttribute < BufferAttribute
    def initialize(array, item_size, normalized = false)
      super(array, item_size, normalized, component_type: :uint32)
    end
  end
end
