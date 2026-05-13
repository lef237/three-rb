# frozen_string_literal: true

require_relative "light"

module Three
  class DirectionalLight < Light
    def initialize(color = 0xffffff, intensity = 1)
      super
      @type = "DirectionalLight"
      @position.copy(Object3D::DEFAULT_UP)
    end
  end
end
