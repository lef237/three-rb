# frozen_string_literal: true

require_relative "light"

module Three
  class AmbientLight < Light
    def initialize(color = 0xffffff, intensity = 1)
      super
      @type = "AmbientLight"
    end
  end
end
