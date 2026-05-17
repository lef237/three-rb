# frozen_string_literal: true

require_relative "../core/object3d"

module Three
  class Scene < Object3D
    attr_reader :background, :environment
    attr_reader :fog, :override_material

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

    def fog=(value)
      replace_scene_resource(:fog, value)
    end

    def override_material=(value)
      replace_scene_resource(:override_material, value)
    end

    private

    def replace_scene_resource(name, value)
      current = instance_variable_get(:"@#{name}")
      current.remove_dirty_dependent(self) if current.respond_to?(:remove_dirty_dependent)
      instance_variable_set(:"@#{name}", value)
      value.add_dirty_dependent(self) if value.respond_to?(:add_dirty_dependent)
      mark_dirty!(:scene)
    end
  end
end
