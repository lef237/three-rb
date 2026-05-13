# frozen_string_literal: true

require_relative "light"

module Three
  class HemisphereLight < Light
    attr_reader :ground_color

    def initialize(sky_color = 0xffffff, ground_color = 0xffffff, intensity = 1)
      super(sky_color, intensity)
      @type = "HemisphereLight"
      @ground_color = Color.new(ground_color)
      bind_ground_color_changes
    end

    def ground_color=(value)
      @ground_color = value.is_a?(Color) ? value : Color.new(value)
      bind_ground_color_changes
      mark_dirty!(:light)
    end

    def to_h
      super.merge(
        ground_color: @ground_color.hex
      )
    end

    private

    def bind_ground_color_changes
      @ground_color.on_change { mark_dirty!(:light) }
    end
  end
end
