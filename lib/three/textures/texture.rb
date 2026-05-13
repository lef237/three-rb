# frozen_string_literal: true

require_relative "../core/event_dispatcher"
require_relative "../dirty"
require_relative "../math/math_utils"

module Three
  class Texture < EventDispatcher
    include Dirty

    @next_id = 0

    class << self
      attr_accessor :next_id
    end

    attr_reader :id, :uuid, :source, :flip_y
    attr_accessor :user_data

    def initialize(source = nil, flip_y: true)
      super()
      @id = self.class.allocate_id
      @uuid = MathUtils.generate_uuid
      @source = source
      @flip_y = flip_y
      @user_data = {}
      mark_dirty!
    end

    def source=(value)
      @source = value
      mark_dirty!(:parameters)
    end

    def flip_y=(value)
      @flip_y = value
      mark_dirty!(:parameters)
    end

    def dispose
      dispatch_event(:dispose)
    end

    def to_h
      {
        uuid: @uuid,
        type: "Texture",
        source: @source,
        flip_y: @flip_y
      }
    end

    def self.allocate_id
      id = Texture.next_id
      Texture.next_id += 1
      id
    end
  end
end
