# frozen_string_literal: true

require_relative "../core/buffer_geometry"
require_relative "../materials/mesh_basic_material"
require_relative "group"

module Three
  class Mesh < Object3D
    attr_reader :geometry, :material
    attr_accessor :morph_target_dictionary, :morph_target_influences, :count

    def initialize(geometry = BufferGeometry.new, material = MeshBasicMaterial.new)
      super()
      @type = "Mesh"
      @geometry = geometry
      @material = material
      @morph_target_dictionary = nil
      @morph_target_influences = nil
      @count = 1
    end

    def geometry=(value)
      @geometry = value
      mark_dirty!(:mesh)
    end

    def material=(value)
      @material = value
      mark_dirty!(:mesh)
    end

    def to_h
      super.merge(
        geometry: @geometry.uuid,
        material: @material.respond_to?(:uuid) ? @material.uuid : nil
      )
    end
  end
end
