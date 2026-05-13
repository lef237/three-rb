# frozen_string_literal: true

require_relative "../math/color"
require_relative "mesh_standard_material"

module Three
  class MeshPhysicalMaterial < MeshStandardMaterial
    PHYSICAL_TEXTURE_SLOTS = %i[
      anisotropy_map
      clearcoat_map
      clearcoat_normal_map
      clearcoat_roughness_map
      transmission_map
      thickness_map
      iridescence_map
      iridescence_thickness_map
      sheen_color_map
      sheen_roughness_map
      specular_color_map
      specular_intensity_map
    ].freeze

    TEXTURE_SLOTS = (MeshStandardMaterial::TEXTURE_SLOTS + PHYSICAL_TEXTURE_SLOTS).freeze

    attr_reader :anisotropy, :anisotropy_rotation, :clearcoat, :clearcoat_roughness, :transmission, :thickness, :ior
    attr_reader :iridescence, :iridescence_ior, :iridescence_thickness_range, :sheen, :sheen_color, :sheen_roughness
    attr_reader :dispersion, :specular_intensity, :specular_color, :attenuation_distance, :attenuation_color
    attr_reader(*PHYSICAL_TEXTURE_SLOTS)

    def initialize(parameters = nil)
      super(nil)
      @type = "MeshPhysicalMaterial"
      @anisotropy = 0
      @anisotropy_rotation = 0
      @clearcoat = 0
      @clearcoat_roughness = 0
      @transmission = 0
      @thickness = 0
      @ior = 1.5
      @iridescence = 0
      @iridescence_ior = 1.3
      @iridescence_thickness_range = [100, 400]
      @sheen = 0
      @sheen_color = Color.new(0x000000)
      @sheen_roughness = 1
      @dispersion = 0
      @specular_intensity = 1
      @specular_color = Color.new(0xffffff)
      @attenuation_distance = nil
      @attenuation_color = Color.new(0xffffff)
      PHYSICAL_TEXTURE_SLOTS.each { |slot| instance_variable_set(:"@#{slot}", nil) }
      bind_physical_color_changes
      set_values(parameters) if parameters
      mark_dirty!
    end

    %i[
      anisotropy
      anisotropy_rotation
      clearcoat
      clearcoat_roughness
      transmission
      thickness
      ior
      iridescence
      iridescence_ior
      sheen
      sheen_roughness
      dispersion
      specular_intensity
      attenuation_distance
    ].each do |name|
      define_method("#{name}=") do |value|
        instance_variable_set(:"@#{name}", value)
        mark_dirty!(:parameters)
      end
    end

    def iridescence_thickness_range=(value)
      @iridescence_thickness_range = value&.dup
      mark_dirty!(:parameters)
    end

    def reflectivity
      MathUtils.clamp(2.5 * (@ior - 1) / (@ior + 1), 0, 1)
    end

    def reflectivity=(value)
      return if value.nil?

      @ior = (1 + 0.4 * value) / (1 - 0.4 * value)
      mark_dirty!(:parameters)
    end

    def sheen_color=(value)
      @sheen_color = value.is_a?(Color) ? value : Color.new(value)
      bind_physical_color_changes
      mark_dirty!(:parameters)
    end

    def specular_color=(value)
      @specular_color = value.is_a?(Color) ? value : Color.new(value)
      bind_physical_color_changes
      mark_dirty!(:parameters)
    end

    def attenuation_color=(value)
      @attenuation_color = value.is_a?(Color) ? value : Color.new(value)
      bind_physical_color_changes
      mark_dirty!(:parameters)
    end

    PHYSICAL_TEXTURE_SLOTS.each do |slot|
      define_method(:"#{slot}=") { |value| set_texture_slot(slot, value) }
    end

    def texture_slots
      TEXTURE_SLOTS
    end

    def to_h
      result = super.merge(
        anisotropy: @anisotropy,
        anisotropy_rotation: @anisotropy_rotation,
        clearcoat: @clearcoat,
        clearcoat_roughness: @clearcoat_roughness,
        transmission: @transmission,
        thickness: @thickness,
        ior: @ior,
        reflectivity: reflectivity,
        iridescence: @iridescence,
        iridescence_ior: @iridescence_ior,
        iridescence_thickness_range: @iridescence_thickness_range&.dup,
        sheen: @sheen,
        sheen_color: @sheen_color.hex,
        sheen_roughness: @sheen_roughness,
        dispersion: @dispersion,
        specular_intensity: @specular_intensity,
        specular_color: @specular_color.hex,
        attenuation_distance: @attenuation_distance,
        attenuation_color: @attenuation_color.hex
      )
      PHYSICAL_TEXTURE_SLOTS.each { |slot| result[slot] = public_send(slot)&.to_h }
      result
    end

    private

    def bind_physical_color_changes
      @sheen_color.on_change { mark_dirty!(:parameters) }
      @specular_color.on_change { mark_dirty!(:parameters) }
      @attenuation_color.on_change { mark_dirty!(:parameters) }
    end
  end
end
