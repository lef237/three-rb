# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "three"

module MathAssertions
  def assert_vector3_in_delta(expected, actual, delta = 1e-12)
    assert_in_delta expected[0], actual.x, delta
    assert_in_delta expected[1], actual.y, delta
    assert_in_delta expected[2], actual.z, delta
  end

  def assert_quaternion_in_delta(expected, actual, delta = 1e-12)
    assert_in_delta expected[0], actual.x, delta
    assert_in_delta expected[1], actual.y, delta
    assert_in_delta expected[2], actual.z, delta
    assert_in_delta expected[3], actual.w, delta
  end
end

Minitest::Test.include MathAssertions
