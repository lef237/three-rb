# frozen_string_literal: true

require_relative "../constants"
require_relative "../core/event_dispatcher"
require_relative "../math/math_utils"

module Three
  class Material < EventDispatcher
    @next_id = 0

    class << self
      attr_accessor :next_id
    end

    attr_reader :id, :uuid
    attr_accessor :name, :type, :side, :opacity, :transparent, :visible, :user_data
    attr_accessor :blending, :vertex_colors, :needs_update

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
