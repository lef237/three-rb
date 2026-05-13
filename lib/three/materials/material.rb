# frozen_string_literal: true

require_relative "../constants"
require_relative "../core/event_dispatcher"
require_relative "../dirty"
require_relative "../math/math_utils"

module Three
  class Material < EventDispatcher
    include Dirty

    @next_id = 0

    class << self
      attr_accessor :next_id
    end

    attr_reader :id, :uuid
    attr_reader :name, :type, :side, :opacity, :transparent, :visible, :blending, :vertex_colors
    attr_accessor :user_data

    def initialize(parameters = nil)
      super()
      @id = self.class.allocate_id
      @uuid = MathUtils.generate_uuid
      @name = ""
      @type = "Material"
      @blending = NormalBlending
      @side = FrontSide
      @vertex_colors = false
      @opacity = 1
      @transparent = false
      @visible = true
      @user_data = {}
      @needs_update = false
      set_values(parameters) if parameters
      mark_dirty!
    end

    def name=(value)
      @name = value
      mark_dirty!(:parameters)
    end

    def type=(value)
      @type = value
      mark_dirty!(:parameters)
    end

    def blending=(value)
      @blending = value
      mark_dirty!(:parameters)
    end

    def side=(value)
      @side = value
      mark_dirty!(:parameters)
    end

    def vertex_colors=(value)
      @vertex_colors = value
      mark_dirty!(:parameters)
    end

    def opacity=(value)
      @opacity = value
      mark_dirty!(:parameters)
    end

    def transparent=(value)
      @transparent = value
      mark_dirty!(:parameters)
    end

    def visible=(value)
      @visible = value
      mark_dirty!(:parameters)
    end

    def needs_update
      @needs_update
    end

    def needs_update=(value)
      @needs_update = value
      mark_dirty!(:parameters) if value
    end

    def needs_update!
      self.needs_update = true
      self
    end

    def self.allocate_id
      id = Material.next_id
      Material.next_id += 1
      id
    end

    def set_values(values)
      values.each do |key, value|
        setter = "#{key}="
        next unless respond_to?(setter)

        current_value = public_send(key) if respond_to?(key)
        if current_value.respond_to?(:set)
          current_value.set(value)
        else
          public_send(setter, value)
        end
      end
      self
    end

    def dispose
      dispatch_event(:dispose)
    end

    def texture_slots
      respond_to?(:map) ? [:map] : []
    end

    def textures
      texture_slots.each_with_object([]) do |slot, result|
        texture = public_send(slot)
        result << texture if texture && !result.include?(texture)
      end
    end

    def to_h
      {
        uuid: @uuid,
        type: @type,
        name: @name,
        side: @side,
        opacity: @opacity,
        transparent: @transparent,
        visible: @visible
      }
    end
  end
end
