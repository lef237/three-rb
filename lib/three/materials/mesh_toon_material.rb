# frozen_string_literal: true

require_relative "../math/color"
require_relative "material"

module Three
  class MeshToonMaterial < Material
    TEXTURE_SLOTS = %i[
      map
      gradient_map
      light_map
      ao_map
      emissive_map
      bump_map
      normal_map
      displacement_map
      alpha_map
    ].freeze

    attr_reader :color, :emissive, :wireframe, :wireframe_linewidth, :fog, :flat_shading
    attr_reader(*TEXTURE_SLOTS)

    def initialize(parameters = nil)
      super(nil)
      @type = "MeshToonMaterial"
      @color = Color.new(0xffffff)
      @emissive = Color.new(0x000000)
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

    def emissive=(value)
      @emissive = value.is_a?(Color) ? value : Color.new(value)
      bind_color_changes
      mark_dirty!(:parameters)
    end

    TEXTURE_SLOTS.each do |slot|
      define_method(:"#{slot}=") { |value| replace_texture_slot(slot, value) }
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
        emissive: @emissive.hex,
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
      @emissive.on_change { mark_dirty!(:parameters) }
    end
  end
end
