# frozen_string_literal: true

require_relative "../backends/threejs"

module Three
  module Postprocessing
    class UnrealBloomPass
      PROPERTY_NAMES = {
        enabled: "enabled",
        strength: "strength",
        radius: "radius",
        threshold: "threshold"
      }.freeze

      attr_reader :backend, :handle, :resolution
      attr_reader(*PROPERTY_NAMES.keys)

      def initialize(resolution: [1, 1], strength: 1, radius: 0, threshold: 0, backend: nil, composer: nil, **parameters)
        @backend = backend || composer&.backend || Backends::ThreeJS.new
        @resolution = coerce_resolution(resolution)
        @enabled = true
        @strength = strength
        @radius = radius
        @threshold = threshold
        @handle = @backend.create_unreal_bloom_pass(@resolution, @strength, @radius, @threshold)
        set_values(parameters)
      end

      PROPERTY_NAMES.each do |ruby_name, js_name|
        define_method("#{ruby_name}=") do |value|
          instance_variable_set("@#{ruby_name}", value)
          @backend.set_postprocessing_pass_property(@handle, js_name, value) if @handle
          value
        end
      end

      private

      def coerce_resolution(value)
        if value.respond_to?(:to_a)
          result = value.to_a
          return result if result.length == 2
        end

        raise TypeError, "resolution must be an array-like [width, height]"
      end

      def set_values(parameters)
        parameters.each do |key, value|
          setter = "#{key}="
          public_send(setter, value) if respond_to?(setter)
        end
      end
    end
  end
end
