# frozen_string_literal: true

require "test_helper"

class ThreeTextureTest < Minitest::Test
  def test_defaults
    texture = Three::Texture.new("/texture.png")

    assert_equal "/texture.png", texture.source
    assert texture.flip_y
    assert_equal Three::ClampToEdgeWrapping, texture.wrap_s
    assert_equal Three::ClampToEdgeWrapping, texture.wrap_t
    assert_equal Three::LinearFilter, texture.mag_filter
    assert_equal Three::LinearMipmapLinearFilter, texture.min_filter
    assert_equal [1, 1], texture.repeat.to_a
    assert texture.uuid
  end

  def test_marks_dirty_when_source_changes
    texture = Three::Texture.new("/texture.png")
    texture.mark_clean!

    texture.source = "/other.png"

    assert texture.dirty_field?(:parameters)
  end

  def test_marks_dirty_when_texture_parameters_change
    texture = Three::Texture.new("/texture.png")
    texture.mark_clean!

    texture.wrap_s = Three::RepeatWrapping
    texture.wrap_t = Three::MirroredRepeatWrapping
    texture.mag_filter = Three::NearestFilter
    texture.min_filter = Three::NearestMipmapNearestFilter

    assert texture.dirty_field?(:parameters)
    assert_equal Three::RepeatWrapping, texture.wrap_s
    assert_equal Three::MirroredRepeatWrapping, texture.wrap_t
    assert_equal Three::NearestFilter, texture.mag_filter
    assert_equal Three::NearestMipmapNearestFilter, texture.min_filter
  end

  def test_marks_dirty_when_repeat_vector_changes
    texture = Three::Texture.new("/texture.png", repeat: [2, 3])
    texture.mark_clean!

    texture.repeat.set(4, 5)

    assert texture.dirty_field?(:parameters)
    assert_equal [4, 5], texture.repeat.to_a
  end

  def test_rejects_invalid_repeat_values
    error = assert_raises(TypeError) do
      Three::Texture.new("/texture.png", repeat: 2)
    end

    assert_match(/repeat must be/, error.message)
  end

  def test_to_h
    texture = Three::Texture.new(
      "/texture.png",
      flip_y: false,
      wrap_s: Three::RepeatWrapping,
      wrap_t: Three::MirroredRepeatWrapping,
      mag_filter: Three::NearestFilter,
      min_filter: Three::NearestMipmapNearestFilter,
      repeat: Three::Vector2.new(2, 3)
    )

    assert_equal "Texture", texture.to_h[:type]
    assert_equal "/texture.png", texture.to_h[:source]
    refute texture.to_h[:flip_y]
    assert_equal Three::RepeatWrapping, texture.to_h[:wrap_s]
    assert_equal Three::MirroredRepeatWrapping, texture.to_h[:wrap_t]
    assert_equal Three::NearestFilter, texture.to_h[:mag_filter]
    assert_equal Three::NearestMipmapNearestFilter, texture.to_h[:min_filter]
    assert_equal [2, 3], texture.to_h[:repeat]
  end
end
