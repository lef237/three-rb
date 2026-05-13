# frozen_string_literal: true

require "securerandom"

module Three
  module MathUtils
    DEG2RAD = Math::PI / 180.0
    RAD2DEG = 180.0 / Math::PI

    module_function

    def clamp(value, min, max)
      [[value, min].max, max].min
    end

    def euclidean_modulo(n, m)
      ((n % m) + m) % m
    end

    def lerp(x, y, t)
      (1 - t) * x + t * y
    end

    def deg_to_rad(degrees)
      degrees * DEG2RAD
    end

    def rad_to_deg(radians)
      radians * RAD2DEG
    end

    def generate_uuid
      SecureRandom.uuid
    end
  end
end
