# frozen_string_literal: true

require_relative "math_utils"

module Three
  class Quaternion
    include Enumerable

    attr_reader :x, :y, :z, :w

    def initialize(x = 0, y = 0, z = 0, w = 1)
      @x = x
      @y = y
      @z = z
      @w = w
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

    def w=(value)
      @w = value
      changed!
    end

    def set(x, y, z, w, update: true)
      @x = x
      @y = y
      @z = z
      @w = w
      changed! if update
      self
    end

    def identity(update: true)
      set(0, 0, 0, 1, update: update)
    end

    def clone
      self.class.new(@x, @y, @z, @w)
    end

    def copy(quaternion, update: true)
      set(quaternion.x, quaternion.y, quaternion.z, quaternion.w, update: update)
    end

    def set_from_euler(euler, update: true)
      c1 = Math.cos(euler.x / 2.0)
      c2 = Math.cos(euler.y / 2.0)
      c3 = Math.cos(euler.z / 2.0)
      s1 = Math.sin(euler.x / 2.0)
      s2 = Math.sin(euler.y / 2.0)
      s3 = Math.sin(euler.z / 2.0)

      case euler.order
      when "XYZ"
        @x = s1 * c2 * c3 + c1 * s2 * s3
        @y = c1 * s2 * c3 - s1 * c2 * s3
        @z = c1 * c2 * s3 + s1 * s2 * c3
        @w = c1 * c2 * c3 - s1 * s2 * s3
      when "YXZ"
        @x = s1 * c2 * c3 + c1 * s2 * s3
        @y = c1 * s2 * c3 - s1 * c2 * s3
        @z = c1 * c2 * s3 - s1 * s2 * c3
        @w = c1 * c2 * c3 + s1 * s2 * s3
      when "ZXY"
        @x = s1 * c2 * c3 - c1 * s2 * s3
        @y = c1 * s2 * c3 + s1 * c2 * s3
        @z = c1 * c2 * s3 + s1 * s2 * c3
        @w = c1 * c2 * c3 - s1 * s2 * s3
      when "ZYX"
        @x = s1 * c2 * c3 - c1 * s2 * s3
        @y = c1 * s2 * c3 + s1 * c2 * s3
        @z = c1 * c2 * s3 - s1 * s2 * c3
        @w = c1 * c2 * c3 + s1 * s2 * s3
      when "YZX"
        @x = s1 * c2 * c3 + c1 * s2 * s3
        @y = c1 * s2 * c3 + s1 * c2 * s3
        @z = c1 * c2 * s3 - s1 * s2 * c3
        @w = c1 * c2 * c3 - s1 * s2 * s3
      when "XZY"
        @x = s1 * c2 * c3 - c1 * s2 * s3
        @y = c1 * s2 * c3 - s1 * c2 * s3
        @z = c1 * c2 * s3 + s1 * s2 * c3
        @w = c1 * c2 * c3 + s1 * s2 * s3
      else
        raise ArgumentError, "unknown Euler order: #{euler.order}"
      end

      changed! if update
      self
    end

    def set_from_axis_angle(axis, angle, update: true)
      half_angle = angle / 2.0
      s = Math.sin(half_angle)

      @x = axis.x * s
      @y = axis.y * s
      @z = axis.z * s
      @w = Math.cos(half_angle)
      changed! if update
      self
    end

    def set_from_rotation_matrix(matrix, update: true)
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
      trace = m11 + m22 + m33

      if trace.positive?
        s = 0.5 / Math.sqrt(trace + 1.0)
        @w = 0.25 / s
        @x = (m32 - m23) * s
        @y = (m13 - m31) * s
        @z = (m21 - m12) * s
      elsif m11 > m22 && m11 > m33
        s = 2.0 * Math.sqrt(1.0 + m11 - m22 - m33)
        @w = (m32 - m23) / s
        @x = 0.25 * s
        @y = (m12 + m21) / s
        @z = (m13 + m31) / s
      elsif m22 > m33
        s = 2.0 * Math.sqrt(1.0 + m22 - m11 - m33)
        @w = (m13 - m31) / s
        @x = (m12 + m21) / s
        @y = 0.25 * s
        @z = (m23 + m32) / s
      else
        s = 2.0 * Math.sqrt(1.0 + m33 - m11 - m22)
        @w = (m21 - m12) / s
        @x = (m13 + m31) / s
        @y = (m23 + m32) / s
        @z = 0.25 * s
      end

      changed! if update
      self
    end

    def multiply(quaternion)
      multiply_quaternions(self, quaternion)
    end

    def premultiply(quaternion)
      multiply_quaternions(quaternion, self)
    end

    def multiply_quaternions(a, b)
      qax = a.x
      qay = a.y
      qaz = a.z
      qaw = a.w
      qbx = b.x
      qby = b.y
      qbz = b.z
      qbw = b.w

      @x = qax * qbw + qaw * qbx + qay * qbz - qaz * qby
      @y = qay * qbw + qaw * qby + qaz * qbx - qax * qbz
      @z = qaz * qbw + qaw * qbz + qax * qby - qay * qbx
      @w = qaw * qbw - qax * qbx - qay * qby - qaz * qbz
      changed!
      self
    end

    def conjugate
      @x *= -1
      @y *= -1
      @z *= -1
      changed!
      self
    end

    def invert
      conjugate
    end

    def dot(quaternion)
      @x * quaternion.x + @y * quaternion.y + @z * quaternion.z + @w * quaternion.w
    end

    def length_sq
      dot(self)
    end

    def length
      Math.sqrt(length_sq)
    end

    def normalize
      current_length = length

      if current_length.zero?
        @x = 0
        @y = 0
        @z = 0
        @w = 1
      else
        scale = 1.0 / current_length
        @x *= scale
        @y *= scale
        @z *= scale
        @w *= scale
      end

      changed!
      self
    end

    def equals?(quaternion, epsilon: 0.0)
      (@x - quaternion.x).abs <= epsilon &&
        (@y - quaternion.y).abs <= epsilon &&
        (@z - quaternion.z).abs <= epsilon &&
        (@w - quaternion.w).abs <= epsilon
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
      yield @w
    end

    def to_a
      [@x, @y, @z, @w]
    end

    def deconstruct
      to_a
    end

    def inspect
      "#<#{self.class} x=#{@x.inspect} y=#{@y.inspect} z=#{@z.inspect} w=#{@w.inspect}>"
    end

    private

    def changed!
      @on_change_callback.call
    end
  end
end
