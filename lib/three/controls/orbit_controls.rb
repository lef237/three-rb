# frozen_string_literal: true

require_relative "../backends/threejs"
require_relative "../math/vector3"

module Three
  module Controls
    class OrbitControls
      PROPERTY_NAMES = {
        enabled: "enabled",
        enable_damping: "enableDamping",
        damping_factor: "dampingFactor",
        enable_zoom: "enableZoom",
        zoom_speed: "zoomSpeed",
        enable_rotate: "enableRotate",
        rotate_speed: "rotateSpeed",
        enable_pan: "enablePan",
        pan_speed: "panSpeed",
        auto_rotate: "autoRotate",
        auto_rotate_speed: "autoRotateSpeed",
        min_distance: "minDistance",
        max_distance: "maxDistance",
        min_zoom: "minZoom",
        max_zoom: "maxZoom"
      }.freeze

      attr_reader :object, :renderer, :backend, :handle, :dom_element, :target
      attr_reader(*PROPERTY_NAMES.keys)

      def initialize(object, renderer: nil, dom_element: nil, backend: nil, **parameters)
        @object = object
        @renderer = renderer
        @backend = backend || renderer&.backend || Backends::ThreeJS.new
        @dom_element = dom_element || default_dom_element(renderer)
        @target = Vector3.new
        bind_target_changes
        set_defaults

        object_handle = @backend.sync(object)
        @handle = @backend.create_orbit_controls(object_handle, @dom_element)
        set_values(parameters)
      end

      def update
        @backend.update_controls(@handle)
        @backend.sync_object_transform_from_handle(@object)
        self
      end

      def dispose
        @backend.dispose_controls(@handle)
        self
      end

      def target=(value)
        @target = coerce_vector3(value)
        bind_target_changes
        sync_target if @handle
      end

      PROPERTY_NAMES.each do |ruby_name, js_name|
        define_method("#{ruby_name}=") do |value|
          instance_variable_set("@#{ruby_name}", value)
          @backend.set_control_property(@handle, js_name, value) if @handle
          value
        end
      end

      private

      def set_defaults
        @enabled = true
        @enable_damping = false
        @damping_factor = 0.05
        @enable_zoom = true
        @zoom_speed = 1.0
        @enable_rotate = true
        @rotate_speed = 1.0
        @enable_pan = true
        @pan_speed = 1.0
        @auto_rotate = false
        @auto_rotate_speed = 2.0
        @min_distance = 0
        @max_distance = Float::INFINITY
        @min_zoom = 0
        @max_zoom = Float::INFINITY
      end

      def set_values(parameters)
        parameters.each do |key, value|
          setter = "#{key}="
          public_send(setter, value) if respond_to?(setter)
        end
      end

      def default_dom_element(renderer)
        return nil unless renderer

        renderer.dom_element
      end

      def coerce_vector3(value)
        return value if value.is_a?(Vector3)
        return Vector3.new(*value) if value.respond_to?(:to_ary)

        raise TypeError, "target must be a Three::Vector3 or an array-like [x, y, z]"
      end

      def bind_target_changes
        @target.on_change { sync_target if @handle }
      end

      def sync_target
        @backend.set_orbit_controls_target(@handle, @target.to_a)
      end
    end
  end
end
