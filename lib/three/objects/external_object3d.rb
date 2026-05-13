# frozen_string_literal: true

require_relative "../core/object3d"

module Three
  class ExternalObject3D < Object3D
    attr_reader :handle

    def initialize(handle, type: "ExternalObject3D")
      super()
      @handle = handle
      @type = type
      mark_clean!
    end
  end
end
