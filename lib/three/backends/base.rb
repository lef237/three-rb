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
    end
  end
end
