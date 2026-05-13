# frozen_string_literal: true

require_relative "../core/object3d"

module Three
  class Group < Object3D
    def initialize
      super
      @type = "Group"
    end
  end
end
