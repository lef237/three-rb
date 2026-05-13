# frozen_string_literal: true

module Three
  class Vector3
    include Enumerable

    attr_accessor :x, :y, :z

    def initialize(x = 0, y = 0, z = 0)
      @x = x
      @y = y
      @z = z
    end

    def set(x, y, z = @z)
      @x = x
      @y = y
      @z = z
      self
    end

    def set_scalar(scalar)
      @x = scalar
      @y = scalar
      @z = scalar
      self
    end

    def set_x(x)
      @x = x
      self
    end

    def set_y(y)
      @y = y
      self
    end

    def set_z(z)
      @z = z
      self
    end

    def set_component(index, value)
      case index
      when 0 then @x = value
      when 1 then @y = value
      when 2 then @z = value
      else raise IndexError, "index is out of range: #{index}"
      end

      self
    end

    def get_component(index)
      case index
      when 0 then @x
      when 1 then @y
      when 2 then @z
      else raise IndexError, "index is out of range: #{index}"
      end
    end

    alias [] get_component
    alias []= set_component

    def clone
      self.class.new(@x, @y, @z)
    end

    def copy(vector)
      @x = vector.x
      @y = vector.y
      @z = vector.z
      self
    end

    def add(vector)
      @x += vector.x
      @y += vector.y
      @z += vector.z
      self
    end

    def add_scalar(scalar)
      @x += scalar
      @y += scalar
      @z += scalar
      self
    end

    def add_vectors(a, b)
      @x = a.x + b.x
      @y = a.y + b.y
      @z = a.z + b.z
      self
    end

    def add_scaled_vector(vector, scale)
      @x += vector.x * scale
      @y += vector.y * scale
      @z += vector.z * scale
      self
    end

    def sub(vector)
      @x -= vector.x
      @y -= vector.y
      @z -= vector.z
      self
    end

    def sub_scalar(scalar)
      @x -= scalar
      @y -= scalar
      @z -= scalar
      self
    end

    def sub_vectors(a, b)
      @x = a.x - b.x
      @y = a.y - b.y
      @z = a.z - b.z
      self
    end

    def multiply(vector)
      @x *= vector.x
      @y *= vector.y
      @z *= vector.z
      self
    end

    def multiply_scalar(scalar)
      @x *= scalar
      @y *= scalar
      @z *= scalar
      self
    end

    def divide(vector)
      @x = @x.to_f / vector.x
      @y = @y.to_f / vector.y
      @z = @z.to_f / vector.z
      self
    end

    def divide_scalar(scalar)
      multiply_scalar(1.0 / scalar)
    end

    def negate
      multiply_scalar(-1)
    end

    def dot(vector)
      @x * vector.x + @y * vector.y + @z * vector.z
    end

    def cross(vector)
      cross_vectors(self, vector)
    end

    def cross_vectors(a, b)
      ax = a.x
      ay = a.y
      az = a.z
      bx = b.x
      by = b.y
      bz = b.z

      @x = ay * bz - az * by
      @y = az * bx - ax * bz
      @z = ax * by - ay * bx
      self
    end

    def length_sq
      @x * @x + @y * @y + @z * @z
    end

    def length
      Math.sqrt(length_sq)
    end

    def manhattan_length
      @x.abs + @y.abs + @z.abs
    end

    def normalize
      current_length = length
      divide_scalar(current_length.zero? ? 1 : current_length)
    end

    def set_length(value)
      old_length = length
      return self if old_length.zero? || old_length == value

      multiply_scalar(value / old_length)
    end

    def distance_to(vector)
      Math.sqrt(distance_to_squared(vector))
    end

    def distance_to_squared(vector)
      dx = @x - vector.x
      dy = @y - vector.y
      dz = @z - vector.z
      dx * dx + dy * dy + dz * dz
    end

    def equals?(vector, epsilon: 0.0)
      (@x - vector.x).abs <= epsilon &&
        (@y - vector.y).abs <= epsilon &&
        (@z - vector.z).abs <= epsilon
    end

    def ==(other)
      other.is_a?(self.class) && equals?(other)
    end

    def +(other)
      clone.add(other)
    end

    def -(other)
      clone.sub(other)
    end

    def *(scalar)
      clone.multiply_scalar(scalar)
    end

    def /(scalar)
      clone.divide_scalar(scalar)
    end

    def -@
      clone.negate
    end

    def each
      return enum_for(:each) unless block_given?

      yield @x
      yield @y
      yield @z
    end

    def to_a
      [@x, @y, @z]
    end

    def deconstruct
      to_a
    end

    def inspect
      "#<#{self.class} x=#{@x.inspect} y=#{@y.inspect} z=#{@z.inspect}>"
    end
  end
end
