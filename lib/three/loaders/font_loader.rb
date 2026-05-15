# frozen_string_literal: true

require_relative "../backends/threejs"

module Three
  class Font
    attr_reader :handle

    def initialize(handle)
      @handle = handle
    end
  end

  module Loaders
    class FontLoader
      def initialize(adapter: nil, backend: nil)
        @adapter = adapter || backend&.adapter || Backends::ThreeJS::RubyWasmAdapter.new
      end

      def load(source)
        handle = @adapter.load_font(source)
        handle = handle.await if handle.respond_to?(:await)
        font = Font.new(handle)
        yield font if block_given?
        font
      end
    end
  end
end
