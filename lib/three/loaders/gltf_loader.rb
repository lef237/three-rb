# frozen_string_literal: true

require_relative "../backends/threejs"
require_relative "../objects/external_object3d"

module Three
  module Loaders
    class GLTF
      attr_reader :handle, :scene

      def initialize(handle)
        @handle = handle
        @scene = ExternalObject3D.new(read_property(handle, :scene), type: "GLTFScene")
      end

      private

      def read_property(object, name)
        object[name]
      end
    end

    class GLTFLoader
      def initialize(adapter: nil)
        @adapter = adapter || Backends::ThreeJS::RubyWasmAdapter.new
      end

      def load(source)
        result = @adapter.load_gltf(source)
        result = result.await if result.respond_to?(:await)
        gltf = GLTF.new(result)
        yield gltf if block_given?
        gltf
      end
    end
  end
end
