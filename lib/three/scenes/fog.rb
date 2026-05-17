# frozen_string_literal: true

require_relative "../dirty"
require_relative "../math/color"
require_relative "../math/math_utils"

module Three
  class Fog
    include Dirty

    attr_reader :uuid, :color, :name, :type, :near, :far

    def initialize(color = 0xffffff, near: 1, far: 1000, name: "")
      @uuid = MathUtils.generate_uuid
      @type = "Fog"
      @name = name
      @color = color.is_a?(Color) ? color : Color.new(color)
      @near = near
      @far = far
      bind_color_changes
      mark_dirty!
    end

    def name=(value)
      @name = value
      mark_dirty!(:parameters)
    end

    def color=(value)
      @color = value.is_a?(Color) ? value : Color.new(value)
      bind_color_changes
      mark_dirty!(:parameters)
    end

    def near=(value)
      @near = value
      mark_dirty!(:parameters)
    end

    def far=(value)
      @far = value
      mark_dirty!(:parameters)
    end

    def to_h
      {
        type: @type,
        name: @name,
        color: @color.hex,
        near: @near,
        far: @far
      }
    end

    private

    def bind_color_changes
      @color.on_change { mark_dirty!(:parameters) }
    end
  end

  class FogExp2 < Fog
    attr_reader :density

    def initialize(color = 0xffffff, density: 0.00025, name: "")
      super(color, near: nil, far: nil, name: name)
      @type = "FogExp2"
      @density = density
      mark_dirty!
    end

    def density=(value)
      @density = value
      mark_dirty!(:parameters)
    end

    def to_h
      {
        type: @type,
        name: name,
        color: color.hex,
        density: @density
      }
    end
  end
end
