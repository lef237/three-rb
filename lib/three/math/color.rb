# frozen_string_literal: true

module Three
  class Color
    include Enumerable

    attr_reader :r, :g, :b

    DEFAULT = Object.new

    def initialize(r = DEFAULT, g = nil, b = nil)
      @on_change_callback = proc {}

      if r.equal?(DEFAULT)
        set_rgb(1, 1, 1)
      elsif g.nil? && b.nil?
        set(r)
      else
        set_rgb(r, g, b)
      end
    end

    def r=(value)
      @r = value
      changed!
    end

    def g=(value)
      @g = value
      changed!
    end

    def b=(value)
      @b = value
      changed!
    end

    def set(value)
      case value
      when Color
        copy(value)
      when Integer
        set_hex(value)
      when String
        set_style(value)
      else
        set_rgb(value, value, value)
      end
    end

    def set_rgb(r, g, b)
      @r = r
      @g = g
      @b = b
      changed!
      self
    end

    def set_hex(hex)
      hex = hex.to_i
      @r = ((hex >> 16) & 255) / 255.0
      @g = ((hex >> 8) & 255) / 255.0
      @b = (hex & 255) / 255.0
      changed!
      self
    end

    def set_style(style)
      value = style.start_with?("#") ? style[1..] : style
      raise ArgumentError, "unsupported color style: #{style}" unless value&.match?(/\A[0-9a-fA-F]{6}\z/)

      set_hex(value.to_i(16))
    end

    def copy(color)
      @r = color.r
      @g = color.g
      @b = color.b
      changed!
      self
    end

    def clone
      self.class.new(@r, @g, @b)
    end

    def hex
      r = (@r * 255).round.clamp(0, 255)
      g = (@g * 255).round.clamp(0, 255)
      b = (@b * 255).round.clamp(0, 255)
      (r << 16) ^ (g << 8) ^ b
    end

    def equals?(color, epsilon: 0.0)
      (@r - color.r).abs <= epsilon &&
        (@g - color.g).abs <= epsilon &&
        (@b - color.b).abs <= epsilon
    end

    def ==(other)
      other.is_a?(self.class) && equals?(other)
    end

    def each
      return enum_for(:each) unless block_given?

      yield @r
      yield @g
      yield @b
    end

    def to_a
      [@r, @g, @b]
    end

    def deconstruct
      to_a
    end

    def on_change(&callback)
      @on_change_callback = callback || proc {}
      self
    end

    alias _on_change on_change

    private

    def changed!
      @on_change_callback.call
    end
  end
end
