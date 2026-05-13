# frozen_string_literal: true

require_relative "../math/color"
require_relative "material"

module Three
  class MeshStandardMaterial < Material
    TEXTURE_SLOTS = %i[
      map
      alpha_map
      ao_map
      bump_map
      displacement_map
      emissive_map
      env_map
      light_map
      metalness_map
      normal_map
      roughness_map
    ].freeze

    attr_reader :color, :roughness, :metalness, :wireframe, :wireframe_linewidth, :fog, :flat_shading
    attr_reader(*TEXTURE_SLOTS)

    def initialize(parameters = nil)
      super(nil)
      @type = "MeshStandardMaterial"
      @color = Color.new(0xffffff)
      @roughness = 1
      @metalness = 0
      TEXTURE_SLOTS.each { |slot| instance_variable_set(:"@#{slot}", nil) }
      @wireframe = false
      @wireframe_linewidth = 1
      @fog = true
      @flat_shading = false
      bind_color_changes
      set_values(parameters) if parameters
      mark_dirty!
    end

    def color=(value)
      @color = value.is_a?(Color) ? value : Color.new(value)
      bind_color_changes
      mark_dirty!(:parameters)
    end

    def roughness=(value)
      @roughness = value
      mark_dirty!(:parameters)
    end

    def metalness=(value)
      @metalness = value
      mark_dirty!(:parameters)
    end

    def map=(value)
      set_texture_slot(:map, value)
    end

    def alpha_map=(value)
      set_texture_slot(:alpha_map, value)
    end

    def ao_map=(value)
      set_texture_slot(:ao_map, value)
    end

    def bump_map=(value)
      set_texture_slot(:bump_map, value)
    end

    def displacement_map=(value)
      set_texture_slot(:displacement_map, value)
    end

    def emissive_map=(value)
      set_texture_slot(:emissive_map, value)
    end

    def env_map=(value)
      set_texture_slot(:env_map, value)
    end

    def light_map=(value)
      set_texture_slot(:light_map, value)
    end

    def metalness_map=(value)
      set_texture_slot(:metalness_map, value)
    end

    def normal_map=(value)
      set_texture_slot(:normal_map, value)
    end

    def roughness_map=(value)
      set_texture_slot(:roughness_map, value)
    end

    def wireframe=(value)
      @wireframe = value
      mark_dirty!(:parameters)
    end

    def wireframe_linewidth=(value)
      @wireframe_linewidth = value
      mark_dirty!(:parameters)
    end

    def fog=(value)
      @fog = value
      mark_dirty!(:parameters)
    end

    def flat_shading=(value)
      @flat_shading = value
      mark_dirty!(:parameters)
    end

    def texture_slots
      TEXTURE_SLOTS
    end

    def to_h
      result = super.merge(
        color: @color.hex,
        roughness: @roughness,
        metalness: @metalness,
        wireframe: @wireframe,
        wireframe_linewidth: @wireframe_linewidth,
        fog: @fog,
        flat_shading: @flat_shading
      )
      TEXTURE_SLOTS.each { |slot| result[slot] = public_send(slot)&.to_h }
      result
    end

    private

    def bind_color_changes
      @color.on_change { mark_dirty!(:parameters) }
    end

    def set_texture_slot(slot, value)
      replace_texture_slot(slot, value)
    end
  end
end
