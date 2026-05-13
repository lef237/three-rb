# frozen_string_literal: true

require_relative "../core/object3d"

module Three
  class Scene < Object3D
    attr_accessor :background, :environment, :fog, :override_material

    def initialize
      super
      @type = "Scene"
      @background = nil
      @environment = nil
      @fog = nil
      @override_material = nil
    end
  end
end
