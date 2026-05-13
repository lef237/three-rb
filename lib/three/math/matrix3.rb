# frozen_string_literal: true

module Three
  class Matrix3
    attr_reader :elements

    def initialize(*values)
      @elements = [
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
      ]

      set(*values) unless values.empty?
    end

    def set(n11, n12, n13, n21, n22, n23, n31, n32, n33)
      @elements[0] = n11
      @elements[3] = n12
      @elements[6] = n13
      @elements[1] = n21
      @elements[4] = n22
      @elements[7] = n23
      @elements[2] = n31
      @elements[5] = n32
      @elements[8] = n33
      self
    end

    def identity
      set(
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
      )
    end

    def clone
      self.class.new.from_array(@elements)
    end

    def copy(matrix)
      @elements = matrix.elements.dup
      self
    end

    def set_from_matrix4(matrix)
      me = matrix.elements
      set(
        me[0], me[4], me[8],
        me[1], me[5], me[9],
        me[2], me[6], me[10]
      )
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
      a12 = ae[3]
      a13 = ae[6]
      a21 = ae[1]
      a22 = ae[4]
      a23 = ae[7]
      a31 = ae[2]
      a32 = ae[5]
      a33 = ae[8]

      b11 = be[0]
      b12 = be[3]
      b13 = be[6]
      b21 = be[1]
      b22 = be[4]
      b23 = be[7]
      b31 = be[2]
      b32 = be[5]
      b33 = be[8]

      @elements[0] = a11 * b11 + a12 * b21 + a13 * b31
      @elements[3] = a11 * b12 + a12 * b22 + a13 * b32
      @elements[6] = a11 * b13 + a12 * b23 + a13 * b33

      @elements[1] = a21 * b11 + a22 * b21 + a23 * b31
      @elements[4] = a21 * b12 + a22 * b22 + a23 * b32
      @elements[7] = a21 * b13 + a22 * b23 + a23 * b33

      @elements[2] = a31 * b11 + a32 * b21 + a33 * b31
      @elements[5] = a31 * b12 + a32 * b22 + a33 * b32
      @elements[8] = a31 * b13 + a32 * b23 + a33 * b33
      self
    end

    def multiply_scalar(scalar)
      @elements.map! { |value| value * scalar }
      self
    end

    def determinant
      a = @elements[0]
      b = @elements[1]
      c = @elements[2]
      d = @elements[3]
      e = @elements[4]
      f = @elements[5]
      g = @elements[6]
      h = @elements[7]
      i = @elements[8]

      a * e * i - a * f * h - b * d * i + b * f * g + c * d * h - c * e * g
    end

    def invert
      n11 = @elements[0]
      n21 = @elements[1]
      n31 = @elements[2]
      n12 = @elements[3]
      n22 = @elements[4]
      n32 = @elements[5]
      n13 = @elements[6]
      n23 = @elements[7]
      n33 = @elements[8]

      t11 = n33 * n22 - n32 * n23
      t12 = n32 * n13 - n33 * n12
      t13 = n23 * n12 - n22 * n13
      det = n11 * t11 + n21 * t12 + n31 * t13
      return set(0, 0, 0, 0, 0, 0, 0, 0, 0) if det.zero?

      det_inv = 1.0 / det

      @elements[0] = t11 * det_inv
      @elements[1] = (n31 * n23 - n33 * n21) * det_inv
      @elements[2] = (n32 * n21 - n31 * n22) * det_inv
      @elements[3] = t12 * det_inv
      @elements[4] = (n33 * n11 - n31 * n13) * det_inv
      @elements[5] = (n31 * n12 - n32 * n11) * det_inv
      @elements[6] = t13 * det_inv
      @elements[7] = (n21 * n13 - n23 * n11) * det_inv
      @elements[8] = (n22 * n11 - n21 * n12) * det_inv
      self
    end

    def transpose
      @elements[1], @elements[3] = @elements[3], @elements[1]
      @elements[2], @elements[6] = @elements[6], @elements[2]
      @elements[5], @elements[7] = @elements[7], @elements[5]
      self
    end

    def get_normal_matrix(matrix4)
      set_from_matrix4(matrix4).invert.transpose
    end

    def set_uv_transform(tx, ty, sx, sy, rotation, cx, cy)
      c = Math.cos(rotation)
      s = Math.sin(rotation)

      set(
        sx * c, sx * s, -sx * (c * cx + s * cy) + cx + tx,
        -sy * s, sy * c, -sy * (-s * cx + c * cy) + cy + ty,
        0, 0, 1
      )
    end

    def scale(sx, sy)
      @elements[0] *= sx
      @elements[3] *= sx
      @elements[6] *= sx
      @elements[1] *= sy
      @elements[4] *= sy
      @elements[7] *= sy
      self
    end

    def rotate(theta)
      c = Math.cos(theta)
      s = Math.sin(theta)

      a11 = @elements[0]
      a12 = @elements[3]
      a13 = @elements[6]
      a21 = @elements[1]
      a22 = @elements[4]
      a23 = @elements[7]

      @elements[0] = c * a11 + s * a21
      @elements[3] = c * a12 + s * a22
      @elements[6] = c * a13 + s * a23
      @elements[1] = -s * a11 + c * a21
      @elements[4] = -s * a12 + c * a22
      @elements[7] = -s * a13 + c * a23
      self
    end

    def translate(tx, ty)
      @elements[0] += tx * @elements[2]
      @elements[3] += tx * @elements[5]
      @elements[6] += tx * @elements[8]
      @elements[1] += ty * @elements[2]
      @elements[4] += ty * @elements[5]
      @elements[7] += ty * @elements[8]
      self
    end

    def transpose_into_array(array = [])
      array[0] = @elements[0]
      array[1] = @elements[3]
      array[2] = @elements[6]
      array[3] = @elements[1]
      array[4] = @elements[4]
      array[5] = @elements[7]
      array[6] = @elements[2]
      array[7] = @elements[5]
      array[8] = @elements[8]
      array
    end

    def from_array(array, offset = 0)
      9.times { |index| @elements[index] = array[index + offset] }
      self
    end

    def to_a
      @elements.dup
    end

    def to_array(array = [], offset = 0)
      9.times { |index| array[index + offset] = @elements[index] }
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
