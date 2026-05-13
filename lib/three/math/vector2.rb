# frozen_string_literal: true

module Three
  class Vector2
    include Enumerable

    attr_reader :x, :y

    def initialize(x = 0, y = 0)
      @x = x
      @y = y
      @on_change_callback = proc {}
    end

    def x=(value)
      @x = value
      changed!
    end

    def y=(value)
      @y = value
      changed!
    end

    def set(x, y)
      @x = x
      @y = y
      changed!
      self
    end

    def set_scalar(scalar)
      set(scalar, scalar)
    end

    def clone
      self.class.new(@x, @y)
    end

    def copy(vector)
      set(vector.x, vector.y)
    end

    def from_array(array, offset = 0)
      set(array[offset], array[offset + 1])
    end

    def to_array(array = [], offset = 0)
      array[offset] = @x
      array[offset + 1] = @y
      array
    end

    def equals?(vector, epsilon: 0.0)
      (@x - vector.x).abs <= epsilon &&
        (@y - vector.y).abs <= epsilon
    end

    def ==(other)
      other.is_a?(self.class) && equals?(other)
    end

    def each
      return enum_for(:each) unless block_given?

      yield @x
      yield @y
    end

    def to_a
      [@x, @y]
    end

    def deconstruct
      to_a
    end

    def on_change(&callback)
      @on_change_callback = callback || proc {}
      self
    end

    alias _on_change on_change

    def inspect
      "#<#{self.class} x=#{@x.inspect} y=#{@y.inspect}>"
    end

    private

    def changed!
      @on_change_callback.call
    end
  end
end
