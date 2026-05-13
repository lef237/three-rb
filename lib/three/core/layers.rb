# frozen_string_literal: true

module Three
  class Layers
    ALL_MASK = 0xffffffff

    attr_reader :mask

    def initialize
      @mask = 1
      @on_change_callback = proc {}
    end

    def mask=(value)
      @mask = value.to_i
      changed!
    end

    def set(channel)
      self.mask = bit(channel)
      self
    end

    def enable(channel)
      self.mask = @mask | bit(channel)
      self
    end

    def enable_all
      self.mask = ALL_MASK
      self
    end

    def toggle(channel)
      self.mask = @mask ^ bit(channel)
      self
    end

    def disable(channel)
      self.mask = @mask & ~bit(channel)
      self
    end

    def disable_all
      self.mask = 0
      self
    end

    def test(layers)
      (@mask & layers.mask) != 0
    end

    def is_enabled(channel)
      (@mask & bit(channel)) != 0
    end

    def on_change(&callback)
      @on_change_callback = callback || proc {}
      self
    end

    private

    def bit(channel)
      channel = Integer(channel)
      raise RangeError, "layer channel must be between 0 and 31" unless channel.between?(0, 31)

      1 << channel
    end

    def changed!
      @on_change_callback.call
    end
  end
end
