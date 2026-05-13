# frozen_string_literal: true

require "test_helper"

class ThreeLightTest < Minitest::Test
  def test_light_defaults
    light = Three::Light.new

    assert_equal "Light", light.type
    assert_equal 0xffffff, light.color.hex
    assert_equal 1, light.intensity
  end

  def test_ambient_light_type
    light = Three::AmbientLight.new(0x334455, 0.4)

    assert_equal "AmbientLight", light.type
    assert_equal 0x334455, light.color.hex
    assert_equal 0.4, light.intensity
  end

  def test_directional_light_defaults_to_default_up_position
    light = Three::DirectionalLight.new(0xffffff, 2)

    assert_equal "DirectionalLight", light.type
    assert_vector3_in_delta [0, 1, 0], light.position
    assert_equal 2, light.intensity
  end

  def test_point_light_accepts_distance_and_decay
    light = Three::PointLight.new(0x112233, 1.5, 12, 1.8)

    assert_equal "PointLight", light.type
    assert_equal 0x112233, light.color.hex
    assert_equal 1.5, light.intensity
    assert_equal 12, light.distance
    assert_equal 1.8, light.decay
  end

  def test_marks_dirty_when_color_changes
    light = Three::AmbientLight.new(0xffffff)
    light.mark_clean!

    light.color.set_hex(0xff0000)

    assert light.dirty_field?(:light)
  end

  def test_marks_dirty_when_intensity_changes
    light = Three::DirectionalLight.new
    light.mark_clean!

    light.intensity = 0.25

    assert light.dirty_field?(:light)
  end

  def test_marks_dirty_when_point_light_distance_or_decay_changes
    light = Three::PointLight.new
    light.mark_clean!

    light.distance = 5
    light.decay = 1.5

    assert light.dirty_field?(:light)
    assert_equal 5, light.distance
    assert_equal 1.5, light.decay
  end

  def test_point_light_to_h
    light = Three::PointLight.new(0xffffff, 2, 8, 2)

    assert_equal "PointLight", light.to_h[:type]
    assert_equal 8, light.to_h[:distance]
    assert_equal 2, light.to_h[:decay]
  end
end
