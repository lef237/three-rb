# frozen_string_literal: true

require_relative "vector3"

module Three
  class Matrix4
    attr_reader :elements

    def initialize(*values)
      @elements = [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
      ]

      set(*values) unless values.empty?
    end

    def set(n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44)
      @elements[0] = n11
      @elements[4] = n12
      @elements[8] = n13
      @elements[12] = n14
      @elements[1] = n21
      @elements[5] = n22
      @elements[9] = n23
      @elements[13] = n24
      @elements[2] = n31
      @elements[6] = n32
      @elements[10] = n33
      @elements[14] = n34
      @elements[3] = n41
      @elements[7] = n42
      @elements[11] = n43
      @elements[15] = n44
      self
    end

    def identity
      set(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
      )
    end

    def clone
      self.class.new.from_array(@elements)
    end

    def copy(matrix)
      @elements = matrix.elements.dup
      self
    end

    def copy_position(matrix)
      @elements[12] = matrix.elements[12]
      @elements[13] = matrix.elements[13]
      @elements[14] = matrix.elements[14]
      self
    end

    def make_translation(x, y = nil, z = nil)
      if y.nil? && z.nil?
        y = x.y
        z = x.z
        x = x.x
      end

      set(
        1, 0, 0, x,
        0, 1, 0, y,
        0, 0, 1, z,
        0, 0, 0, 1
      )
    end

    def make_scale(x, y, z)
      set(
        x, 0, 0, 0,
        0, y, 0, 0,
        0, 0, z, 0,
        0, 0, 0, 1
      )
    end

    def make_rotation_from_quaternion(quaternion)
      compose(Vector3.new, quaternion, Vector3.new(1, 1, 1))
    end

    def set_position(x, y = nil, z = nil)
      if y.nil? && z.nil?
        @elements[12] = x.x
        @elements[13] = x.y
        @elements[14] = x.z
      else
        @elements[12] = x
        @elements[13] = y
        @elements[14] = z
      end

      self
    end

    def multiply(matrix)
      multiply_matrices(self, matrix)
    end

    def premultiply(matrix)
      multiply_matrices(matrix, self)
    end

    def multiply_matrices(a, b)
      ae = a.elements
      be = b.elements

      a11 = ae[0]
      a12 = ae[4]
      a13 = ae[8]
      a14 = ae[12]
      a21 = ae[1]
      a22 = ae[5]
      a23 = ae[9]
      a24 = ae[13]
      a31 = ae[2]
      a32 = ae[6]
      a33 = ae[10]
      a34 = ae[14]
      a41 = ae[3]
      a42 = ae[7]
      a43 = ae[11]
      a44 = ae[15]

      b11 = be[0]
      b12 = be[4]
      b13 = be[8]
      b14 = be[12]
      b21 = be[1]
      b22 = be[5]
      b23 = be[9]
      b24 = be[13]
      b31 = be[2]
      b32 = be[6]
      b33 = be[10]
      b34 = be[14]
      b41 = be[3]
      b42 = be[7]
      b43 = be[11]
      b44 = be[15]

      @elements[0] = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41
      @elements[4] = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42
      @elements[8] = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43
      @elements[12] = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44

      @elements[1] = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41
      @elements[5] = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42
      @elements[9] = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43
      @elements[13] = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44

      @elements[2] = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41
      @elements[6] = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42
      @elements[10] = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43
      @elements[14] = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44

      @elements[3] = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41
      @elements[7] = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42
      @elements[11] = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43
      @elements[15] = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44
      self
    end

    def multiply_scalar(scalar)
      @elements.map! { |value| value * scalar }
      self
    end

    def determinant
      n11 = @elements[0]
      n12 = @elements[4]
      n13 = @elements[8]
      n14 = @elements[12]
      n21 = @elements[1]
      n22 = @elements[5]
      n23 = @elements[9]
      n24 = @elements[13]
      n31 = @elements[2]
      n32 = @elements[6]
      n33 = @elements[10]
      n34 = @elements[14]
      n41 = @elements[3]
      n42 = @elements[7]
      n43 = @elements[11]
      n44 = @elements[15]

      t11 = n23 * n34 - n24 * n33
      t12 = n22 * n34 - n24 * n32
      t13 = n22 * n33 - n23 * n32
      t21 = n21 * n34 - n24 * n31
      t22 = n21 * n33 - n23 * n31
      t23 = n21 * n32 - n22 * n31

      n11 * (n42 * t11 - n43 * t12 + n44 * t13) -
        n12 * (n41 * t11 - n43 * t21 + n44 * t22) +
        n13 * (n41 * t12 - n42 * t21 + n44 * t23) -
        n14 * (n41 * t13 - n42 * t22 + n43 * t23)
    end

    def transpose
      @elements[1], @elements[4] = @elements[4], @elements[1]
      @elements[2], @elements[8] = @elements[8], @elements[2]
      @elements[6], @elements[9] = @elements[9], @elements[6]
      @elements[3], @elements[12] = @elements[12], @elements[3]
      @elements[7], @elements[13] = @elements[13], @elements[7]
      @elements[11], @elements[14] = @elements[14], @elements[11]
      self
    end

    def invert
      n11 = @elements[0]
      n21 = @elements[1]
      n31 = @elements[2]
      n41 = @elements[3]
      n12 = @elements[4]
      n22 = @elements[5]
      n32 = @elements[6]
      n42 = @elements[7]
      n13 = @elements[8]
      n23 = @elements[9]
      n33 = @elements[10]
      n43 = @elements[11]
      n14 = @elements[12]
      n24 = @elements[13]
      n34 = @elements[14]
      n44 = @elements[15]

      t1 = n11 * n22 - n21 * n12
      t2 = n11 * n32 - n31 * n12
      t3 = n11 * n42 - n41 * n12
      t4 = n21 * n32 - n31 * n22
      t5 = n21 * n42 - n41 * n22
      t6 = n31 * n42 - n41 * n32
      t7 = n13 * n24 - n23 * n14
      t8 = n13 * n34 - n33 * n14
      t9 = n13 * n44 - n43 * n14
      t10 = n23 * n34 - n33 * n24
      t11 = n23 * n44 - n43 * n24
      t12 = n33 * n44 - n43 * n34

      det = t1 * t12 - t2 * t11 + t3 * t10 + t4 * t9 - t5 * t8 + t6 * t7
      return set(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0) if det.zero?

      det_inv = 1.0 / det

      @elements[0] = (n22 * t12 - n32 * t11 + n42 * t10) * det_inv
      @elements[1] = (n31 * t11 - n21 * t12 - n41 * t10) * det_inv
      @elements[2] = (n24 * t6 - n34 * t5 + n44 * t4) * det_inv
      @elements[3] = (n33 * t5 - n23 * t6 - n43 * t4) * det_inv
      @elements[4] = (n32 * t9 - n12 * t12 - n42 * t8) * det_inv
      @elements[5] = (n11 * t12 - n31 * t9 + n41 * t8) * det_inv
      @elements[6] = (n34 * t3 - n14 * t6 - n44 * t2) * det_inv
      @elements[7] = (n13 * t6 - n33 * t3 + n43 * t2) * det_inv
      @elements[8] = (n12 * t11 - n22 * t9 + n42 * t7) * det_inv
      @elements[9] = (n21 * t9 - n11 * t11 - n41 * t7) * det_inv
      @elements[10] = (n14 * t5 - n24 * t3 + n44 * t1) * det_inv
      @elements[11] = (n23 * t3 - n13 * t5 - n43 * t1) * det_inv
      @elements[12] = (n22 * t8 - n12 * t10 - n32 * t7) * det_inv
      @elements[13] = (n11 * t10 - n21 * t8 + n31 * t7) * det_inv
      @elements[14] = (n24 * t2 - n14 * t4 - n34 * t1) * det_inv
      @elements[15] = (n13 * t4 - n23 * t2 + n33 * t1) * det_inv
      self
    end

    def scale(vector)
      @elements[0] *= vector.x
      @elements[4] *= vector.y
      @elements[8] *= vector.z
      @elements[1] *= vector.x
      @elements[5] *= vector.y
      @elements[9] *= vector.z
      @elements[2] *= vector.x
      @elements[6] *= vector.y
      @elements[10] *= vector.z
      @elements[3] *= vector.x
      @elements[7] *= vector.y
      @elements[11] *= vector.z
      self
    end

    def make_perspective(left, right, top, bottom, near, far)
      x = 2.0 * near / (right - left)
      y = 2.0 * near / (top - bottom)
      a = (right + left).to_f / (right - left)
      b = (top + bottom).to_f / (top - bottom)
      c = -(far + near).to_f / (far - near)
      d = (-2.0 * far * near) / (far - near)

      @elements[0] = x
      @elements[4] = 0
      @elements[8] = a
      @elements[12] = 0
      @elements[1] = 0
      @elements[5] = y
      @elements[9] = b
      @elements[13] = 0
      @elements[2] = 0
      @elements[6] = 0
      @elements[10] = c
      @elements[14] = d
      @elements[3] = 0
      @elements[7] = 0
      @elements[11] = -1
      @elements[15] = 0
      self
    end

    def make_orthographic(left, right, top, bottom, near, far)
      w = 1.0 / (right - left)
      h = 1.0 / (top - bottom)
      p = 1.0 / (far - near)
      x = (right + left) * w
      y = (top + bottom) * h
      z = (far + near) * p

      @elements[0] = 2 * w
      @elements[4] = 0
      @elements[8] = 0
      @elements[12] = -x
      @elements[1] = 0
      @elements[5] = 2 * h
      @elements[9] = 0
      @elements[13] = -y
      @elements[2] = 0
      @elements[6] = 0
      @elements[10] = -2 * p
      @elements[14] = -z
      @elements[3] = 0
      @elements[7] = 0
      @elements[11] = 0
      @elements[15] = 1
      self
    end

    def compose(position, quaternion, scale)
      x = quaternion.x
      y = quaternion.y
      z = quaternion.z
      w = quaternion.w
      x2 = x + x
      y2 = y + y
      z2 = z + z
      xx = x * x2
      xy = x * y2
      xz = x * z2
      yy = y * y2
      yz = y * z2
      zz = z * z2
      wx = w * x2
      wy = w * y2
      wz = w * z2
      sx = scale.x
      sy = scale.y
      sz = scale.z

      @elements[0] = (1 - (yy + zz)) * sx
      @elements[1] = (xy + wz) * sx
      @elements[2] = (xz - wy) * sx
      @elements[3] = 0

      @elements[4] = (xy - wz) * sy
      @elements[5] = (1 - (xx + zz)) * sy
      @elements[6] = (yz + wx) * sy
      @elements[7] = 0

      @elements[8] = (xz + wy) * sz
      @elements[9] = (yz - wx) * sz
      @elements[10] = (1 - (xx + yy)) * sz
      @elements[11] = 0

      @elements[12] = position.x
      @elements[13] = position.y
      @elements[14] = position.z
      @elements[15] = 1
      self
    end

    def decompose(position, quaternion, scale)
      position.set(@elements[12], @elements[13], @elements[14])

      det = determinant
      if det.zero?
        scale.set(1, 1, 1)
        quaternion.identity
        return self
      end

      sx = Vector3.new(@elements[0], @elements[1], @elements[2]).length
      sy = Vector3.new(@elements[4], @elements[5], @elements[6]).length
      sz = Vector3.new(@elements[8], @elements[9], @elements[10]).length
      sx = -sx if det.negative?

      matrix = clone
      matrix.elements[0] *= 1.0 / sx
      matrix.elements[1] *= 1.0 / sx
      matrix.elements[2] *= 1.0 / sx
      matrix.elements[4] *= 1.0 / sy
      matrix.elements[5] *= 1.0 / sy
      matrix.elements[6] *= 1.0 / sy
      matrix.elements[8] *= 1.0 / sz
      matrix.elements[9] *= 1.0 / sz
      matrix.elements[10] *= 1.0 / sz

      quaternion.set_from_rotation_matrix(matrix)
      scale.set(sx, sy, sz)
      self
    end

    def from_array(array, offset = 0)
      16.times { |index| @elements[index] = array[index + offset] }
      self
    end

    def to_a
      @elements.dup
    end

    def to_array(array = [], offset = 0)
      16.times { |index| array[index + offset] = @elements[index] }
      array
    end

    def equals?(matrix, epsilon: 0.0)
      @elements.each_with_index.all? do |value, index|
        (value - matrix.elements[index]).abs <= epsilon
      end
    end

    def ==(other)
      other.is_a?(self.class) && equals?(other)
    end

    def inspect
      "#<#{self.class} elements=#{@elements.inspect}>"
    end
  end
end
