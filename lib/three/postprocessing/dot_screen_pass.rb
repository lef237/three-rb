# frozen_string_literal: true

require_relative "../backends/threejs"
require_relative "../math/vector2"

module Three
  module Postprocessing
    class DotScreenPass
      PROPERTY_NAMES = {
        enabled: "enabled"
      }.freeze

      attr_reader :backend, :handle, :center, :angle, :scale
      attr_reader(*PROPERTY_NAMES.keys)

      def initialize(center: [0.5, 0.5], angle: 1.57, scale: 1, backend: nil, composer: nil, **parameters)
        @backend = backend || composer&.backend || Backends::ThreeJS.new
        @center = coerce_center(center)
        @angle = angle
        @scale = scale
        @enabled = true
        @handle = @backend.create_dot_screen_pass(@center.to_a, @angle, @scale)
        bind_center_changes
        set_values(parameters)
      end

      PROPERTY_NAMES.each do |ruby_name, js_name|
        define_method("#{ruby_name}=") do |value|
          instance_variable_set("@#{ruby_name}", value)
          @backend.set_postprocessing_pass_property(@handle, js_name, value) if @handle
          value
        end
      end

      def center=(value)
        @center = coerce_center(value)
        bind_center_changes
        sync_uniform("center", @center.to_a)
        @center
      end

      def angle=(value)
        @angle = value
        sync_uniform("angle", value)
        value
      end

      def scale=(value)
        @scale = value
        sync_uniform("scale", value)
        value
      end

      private

      def coerce_center(value)
        return value if value.is_a?(Vector2)

        if value.respond_to?(:to_a)
          array = value.to_a
          return Vector2.new(array[0], array[1]) if array.length == 2
        end

        raise TypeError, "center must be a Three::Vector2 or an array-like [x, y]"
      end

      def bind_center_changes
        @center.on_change { sync_uniform("center", @center.to_a) }
      end

      def sync_uniform(name, value)
        @backend.set_postprocessing_pass_uniform(@handle, name, value) if @handle
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
