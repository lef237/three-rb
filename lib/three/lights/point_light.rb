# frozen_string_literal: true

require_relative "light"

module Three
  class PointLight < Light
    attr_reader :distance, :decay

    def initialize(color = 0xffffff, intensity = 1, distance = 0, decay = 2)
      super(color, intensity)
      @type = "PointLight"
      @distance = distance
      @decay = decay
    end

    def distance=(value)
      @distance = value
      mark_dirty!(:light)
    end

    def decay=(value)
      @decay = value
      mark_dirty!(:light)
    end

    def to_h
      super.merge(
        distance: @distance,
        decay: @decay
      )
    end
  end
end
