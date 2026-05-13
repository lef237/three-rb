# frozen_string_literal: true

require_relative "math_utils"
require_relative "matrix4"

module Three
  class Euler
    include Enumerable

    DEFAULT_ORDER = "XYZ"
    ORDERS = %w[XYZ YXZ ZXY ZYX YZX XZY].freeze

    attr_reader :x, :y, :z, :order

    def initialize(x = 0, y = 0, z = 0, order = DEFAULT_ORDER)
      validate_order!(order)

      @x = x
      @y = y
      @z = z
      @order = order
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

    def z=(value)
      @z = value
      changed!
    end

    def order=(value)
      validate_order!(value)
      @order = value
      changed!
    end

    def set(x, y, z, order = @order, update: true)
      validate_order!(order)

      @x = x
      @y = y
      @z = z
      @order = order
      changed! if update
      self
    end

    def clone
      self.class.new(@x, @y, @z, @order)
    end

    def copy(euler, update: true)
      set(euler.x, euler.y, euler.z, euler.order, update: update)
    end

    def set_from_rotation_matrix(matrix, order = @order, update: true)
      validate_order!(order)

      elements = matrix.elements
      m11 = elements[0]
      m12 = elements[4]
      m13 = elements[8]
      m21 = elements[1]
      m22 = elements[5]
      m23 = elements[9]
      m31 = elements[2]
      m32 = elements[6]
      m33 = elements[10]

      case order
      when "XYZ"
        @y = Math.asin(MathUtils.clamp(m13, -1, 1))
        if m13.abs < 0.9999999
          @x = Math.atan2(-m23, m33)
          @z = Math.atan2(-m12, m11)
        else
          @x = Math.atan2(m32, m22)
          @z = 0
        end
      when "YXZ"
        @x = Math.asin(-MathUtils.clamp(m23, -1, 1))
        if m23.abs < 0.9999999
          @y = Math.atan2(m13, m33)
          @z = Math.atan2(m21, m22)
        else
          @y = Math.atan2(-m31, m11)
          @z = 0
        end
      when "ZXY"
        @x = Math.asin(MathUtils.clamp(m32, -1, 1))
        if m32.abs < 0.9999999
          @y = Math.atan2(-m31, m33)
          @z = Math.atan2(-m12, m22)
        else
          @y = 0
          @z = Math.atan2(m21, m11)
        end
      when "ZYX"
        @y = Math.asin(-MathUtils.clamp(m31, -1, 1))
        if m31.abs < 0.9999999
          @x = Math.atan2(m32, m33)
          @z = Math.atan2(m21, m11)
        else
          @x = 0
          @z = Math.atan2(-m12, m22)
        end
      when "YZX"
        @z = Math.asin(MathUtils.clamp(m21, -1, 1))
        if m21.abs < 0.9999999
          @x = Math.atan2(-m23, m22)
          @y = Math.atan2(-m31, m11)
        else
          @x = 0
          @y = Math.atan2(m13, m33)
        end
      when "XZY"
        @z = Math.asin(-MathUtils.clamp(m12, -1, 1))
        if m12.abs < 0.9999999
          @x = Math.atan2(m32, m22)
          @y = Math.atan2(m13, m11)
        else
          @x = Math.atan2(-m23, m33)
          @y = 0
        end
      end

      @order = order
      changed! if update
      self
    end

    def set_from_quaternion(quaternion, order = @order, update: true)
      matrix = Matrix4.new.make_rotation_from_quaternion(quaternion)
      set_from_rotation_matrix(matrix, order, update: update)
    end

    def equals?(euler, epsilon: 0.0)
      @order == euler.order &&
        (@x - euler.x).abs <= epsilon &&
        (@y - euler.y).abs <= epsilon &&
        (@z - euler.z).abs <= epsilon
    end

    def ==(other)
      other.is_a?(self.class) && equals?(other)
    end

    def on_change(&callback)
      @on_change_callback = callback || proc {}
      self
    end

    alias _on_change on_change

    def each
      return enum_for(:each) unless block_given?

      yield @x
      yield @y
      yield @z
      yield @order
    end

    def to_a
      [@x, @y, @z, @order]
    end

    def deconstruct
      to_a
    end

    def inspect
      "#<#{self.class} x=#{@x.inspect} y=#{@y.inspect} z=#{@z.inspect} order=#{@order.inspect}>"
    end

    private

    def validate_order!(order)
      return if ORDERS.include?(order)

      raise ArgumentError, "unknown Euler order: #{order}"
    end

    def changed!
      @on_change_callback.call
    end
  end
end
