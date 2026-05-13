# frozen_string_literal: true

require_relative "../backends/threejs"
require_relative "../animation/animation_clip"
require_relative "../objects/external_object3d"

module Three
  module Loaders
    class GLTF
      attr_reader :handle, :scene, :animations

      def initialize(handle, adapter:)
        @handle = handle
        @adapter = adapter
        @scene = ExternalObject3D.new(read_property(handle, :scene), type: "GLTFScene")
        @animations = @adapter.gltf_animations(handle).map do |animation|
          AnimationClip.new(animation, adapter: @adapter)
        end
      end

      private

      def read_property(object, name)
        object[name]
      end
    end

    class GLTFLoader
      def initialize(adapter: nil, backend: nil, draco_decoder_path: nil, draco_decoder_config: nil)
        @adapter = adapter || backend&.adapter || Backends::ThreeJS::RubyWasmAdapter.new
        @draco_decoder_path = draco_decoder_path
        @draco_decoder_config = draco_decoder_config
      end

      def load(source)
        result = @adapter.load_gltf(
          source,
          draco_decoder_path: @draco_decoder_path,
          draco_decoder_config: @draco_decoder_config
        )
        result = result.await if result.respond_to?(:await)
        gltf = GLTF.new(result, adapter: @adapter)
        yield gltf if block_given?
        gltf
      end
    end
  end
end
