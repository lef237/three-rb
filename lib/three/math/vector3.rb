# frozen_string_literal: true

module Three
  class Vector3
    include Enumerable

    attr_reader :x, :y, :z

    def initialize(x = 0, y = 0, z = 0)
      @x = x
      @y = y
      @z = z
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

    def set(x, y, z = @z)
      @x = x
      @y = y
      @z = z
      changed!
      self
    end

    def set_scalar(scalar)
      @x = scalar
      @y = scalar
      @z = scalar
      changed!
      self
    end

    def set_x(x)
      @x = x
      changed!
      self
    end

    def set_y(y)
      @y = y
      changed!
      self
    end

    def set_z(z)
      @z = z
      changed!
      self
    end

    def set_component(index, value)
      case index
      when 0 then @x = value
      when 1 then @y = value
      when 2 then @z = value
      else raise IndexError, "index is out of range: #{index}"
      end

      changed!
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
      changed!
      self
    end

    def add(vector)
      @x += vector.x
      @y += vector.y
      @z += vector.z
      changed!
      self
    end

    def add_scalar(scalar)
      @x += scalar
      @y += scalar
      @z += scalar
      changed!
      self
    end

    def add_vectors(a, b)
      @x = a.x + b.x
      @y = a.y + b.y
      @z = a.z + b.z
      changed!
      self
    end

    def add_scaled_vector(vector, scale)
      @x += vector.x * scale
      @y += vector.y * scale
      @z += vector.z * scale
      changed!
      self
    end

    def sub(vector)
      @x -= vector.x
      @y -= vector.y
      @z -= vector.z
      changed!
      self
    end

    def sub_scalar(scalar)
      @x -= scalar
      @y -= scalar
      @z -= scalar
      changed!
      self
    end

    def sub_vectors(a, b)
      @x = a.x - b.x
      @y = a.y - b.y
      @z = a.z - b.z
      changed!
      self
    end

    def multiply(vector)
      @x *= vector.x
      @y *= vector.y
      @z *= vector.z
      changed!
      self
    end

    def multiply_scalar(scalar)
      @x *= scalar
      @y *= scalar
      @z *= scalar
      changed!
      self
    end

    def divide(vector)
      @x = @x.to_f / vector.x
      @y = @y.to_f / vector.y
      @z = @z.to_f / vector.z
      changed!
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
      changed!
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

    def apply_matrix4(matrix)
      elements = matrix.elements
      x = @x
      y = @y
      z = @z
      w = 1.0 / (elements[3] * x + elements[7] * y + elements[11] * z + elements[15])

      @x = (elements[0] * x + elements[4] * y + elements[8] * z + elements[12]) * w
      @y = (elements[1] * x + elements[5] * y + elements[9] * z + elements[13]) * w
      @z = (elements[2] * x + elements[6] * y + elements[10] * z + elements[14]) * w
      changed!
      self
    end

    def apply_matrix3(matrix)
      elements = matrix.elements
      x = @x
      y = @y
      z = @z

      @x = elements[0] * x + elements[3] * y + elements[6] * z
      @y = elements[1] * x + elements[4] * y + elements[7] * z
      @z = elements[2] * x + elements[5] * y + elements[8] * z
      changed!
      self
    end

    def apply_quaternion(quaternion)
      vx = @x
      vy = @y
      vz = @z
      qx = quaternion.x
      qy = quaternion.y
      qz = quaternion.z
      qw = quaternion.w

      tx = 2 * (qy * vz - qz * vy)
      ty = 2 * (qz * vx - qx * vz)
      tz = 2 * (qx * vy - qy * vx)

      @x = vx + qw * tx + qy * tz - qz * ty
      @y = vy + qw * ty + qz * tx - qx * tz
      @z = vz + qw * tz + qx * ty - qy * tx
      changed!
      self
    end

    def set_from_matrix_position(matrix)
      elements = matrix.elements
      @x = elements[12]
      @y = elements[13]
      @z = elements[14]
      changed!
      self
    end

    def set_from_matrix_scale(matrix)
      sx = set_from_matrix_column(matrix, 0).length
      sy = set_from_matrix_column(matrix, 1).length
      sz = set_from_matrix_column(matrix, 2).length
      set(sx, sy, sz)
    end

    def set_from_matrix_column(matrix, index)
      from_array(matrix.elements, index * 4)
    end

    def set_from_matrix3_column(matrix, index)
      from_array(matrix.elements, index * 3)
    end

    def from_array(array, offset = 0)
      @x = array[offset]
      @y = array[offset + 1]
      @z = array[offset + 2]
      changed!
      self
    end

    def on_change(&callback)
      @on_change_callback = callback || proc {}
      self
    end

    alias _on_change on_change

    def to_array(array = [], offset = 0)
      array[offset] = @x
      array[offset + 1] = @y
      array[offset + 2] = @z
      array
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

    private

    def changed!
      @on_change_callback.call
    end
  end
end
