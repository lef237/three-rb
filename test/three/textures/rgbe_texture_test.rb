# frozen_string_literal: true

require "test_helper"

class ThreeRGBETextureTest < Minitest::Test
  def test_defaults
    texture = Three::RGBETexture.new("/studio.hdr")

    assert_equal "/studio.hdr", texture.source
    assert_equal Three::EquirectangularReflectionMapping, texture.mapping
    assert_equal Three::LinearSRGBColorSpace, texture.color_space
    assert texture.flip_y
    assert_equal Three::LinearFilter, texture.mag_filter
    assert_equal Three::LinearFilter, texture.min_filter
  end

  def test_to_h
    texture = Three::RGBETexture.new("/studio.hdr")

    assert_equal "RGBETexture", texture.to_h[:type]
    assert_equal "/studio.hdr", texture.to_h[:source]
    assert_equal Three::EquirectangularReflectionMapping, texture.to_h[:mapping]
    assert_equal Three::LinearSRGBColorSpace, texture.to_h[:color_space]
  end
end
