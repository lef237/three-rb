# frozen_string_literal: true

module Three
  module Backends
    class Base
      def materialize(_object)
        raise NotImplementedError
      end

      def sync(_object)
        raise NotImplementedError
      end

      def dispose(_object, **_options)
        raise NotImplementedError
      end

      def set_renderer_shadow_map(_renderer_handle, **_options)
        raise NotImplementedError
      end

      def traverse_handles(_object, &_block)
        raise NotImplementedError
      end

      def dispose_subtree(_object, **_options)
        raise NotImplementedError
      end
    end
  end
end
