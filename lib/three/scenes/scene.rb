# frozen_string_literal: true

require_relative "../core/object3d"

module Three
  class Scene < Object3D
    attr_reader :background, :environment
    attr_accessor :fog, :override_material

    def initialize
      super
      @type = "Scene"
      @background = nil
      @environment = nil
      @fog = nil
      @override_material = nil
    end

    def background=(value)
      @background = value
      mark_dirty!(:scene)
    end

    def environment=(value)
      @environment = value
      mark_dirty!(:scene)
    end
  end
end
