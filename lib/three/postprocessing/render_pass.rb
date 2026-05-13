# frozen_string_literal: true

require_relative "../backends/threejs"

module Three
  module Postprocessing
    class RenderPass
      PROPERTY_NAMES = {
        enabled: "enabled"
      }.freeze

      attr_reader :scene, :camera, :backend, :handle
      attr_reader(*PROPERTY_NAMES.keys)

      def initialize(scene, camera, backend: nil, composer: nil, **parameters)
        @scene = scene
        @camera = camera
        @backend = backend || composer&.backend || Backends::ThreeJS.new
        @enabled = true
        @handle = @backend.create_render_pass(scene, camera)
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

      def set_values(parameters)
        parameters.each do |key, value|
          setter = "#{key}="
          public_send(setter, value) if respond_to?(setter)
        end
      end
    end
  end
end
