# frozen_string_literal: true

require_relative "../math/vector2"
require_relative "../math/vector3"
require_relative "../backends/threejs"

module Three
  class Raycaster
    class Intersection
      attr_reader :distance, :point, :object, :object_handle, :uv, :face_index, :index, :instance_id, :raw

      def initialize(distance:, point:, object:, object_handle:, uv: nil, face_index: nil, index: nil, instance_id: nil, raw: nil)
        @distance = distance
        @point = point
        @object = object
        @object_handle = object_handle
        @uv = uv
        @face_index = face_index
        @index = index
        @instance_id = instance_id
        @raw = raw
      end
    end

    attr_reader :backend, :handle

    def initialize(backend: Backends::ThreeJS.new)
      @backend = backend
      @handle = @backend.create_raycaster
    end

    def set_from_camera(coords, camera)
      @backend.set_raycaster_from_camera(@handle, coerce_vector2(coords), camera)
      self
    end

    def intersect_object(object, recursive: false)
      intersect_objects([object], recursive: recursive)
    end

    def intersect_objects(objects, recursive: false)
      @backend.intersect_objects(@handle, objects, recursive: recursive).map do |entry|
        build_intersection(entry)
      end
    end

    private

    def build_intersection(entry)
      Intersection.new(
        distance: entry[:distance],
        point: entry[:point] ? Vector3.new(*entry[:point]) : nil,
        object: entry[:object],
        object_handle: entry[:object_handle],
        uv: entry[:uv] ? Vector2.new(*entry[:uv]) : nil,
        face_index: entry[:face_index],
        index: entry[:index],
        instance_id: entry[:instance_id],
        raw: entry[:raw]
      )
    end

    def coerce_vector2(value)
      return value.to_a if value.is_a?(Vector2)

      array = value.to_ary if value.respond_to?(:to_ary)
      array ||= value.to_a if value.respond_to?(:to_a)
      raise TypeError, "coords must be a Three::Vector2 or an array-like [x, y]" unless array&.length == 2

      array
    end
  end
end
