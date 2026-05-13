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
    assert_equal [0, 0], texture.offset.to_a
    assert_equal [1, 1], texture.repeat.to_a
    assert_equal [0, 0], texture.center.to_a
    assert_equal 0, texture.rotation
    assert texture.matrix_auto_update
    assert_equal Three::Matrix3.new, texture.matrix
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
    texture.rotation = Math::PI / 4
    texture.matrix_auto_update = false

    assert texture.dirty_field?(:parameters)
    assert_equal Three::RepeatWrapping, texture.wrap_s
    assert_equal Three::MirroredRepeatWrapping, texture.wrap_t
    assert_equal Three::NearestFilter, texture.mag_filter
    assert_equal Three::NearestMipmapNearestFilter, texture.min_filter
    assert_equal Math::PI / 4, texture.rotation
    refute texture.matrix_auto_update
  end

  def test_marks_dirty_when_transform_vectors_change
    texture = Three::Texture.new("/texture.png", repeat: [2, 3])
    texture.mark_clean!

    texture.offset.set(0.25, 0.5)
    texture.repeat.set(4, 5)
    texture.center.set(0.5, 0.5)

    assert texture.dirty_field?(:parameters)
    assert_equal [0.25, 0.5], texture.offset.to_a
    assert_equal [4, 5], texture.repeat.to_a
    assert_equal [0.5, 0.5], texture.center.to_a
  end

  def test_update_matrix_uses_uv_transform_parameters
    texture = Three::Texture.new("/texture.png", offset: [1, 2], repeat: [3, 4], center: [0.5, 0.25])
    texture.mark_clean!

    result = texture.update_matrix

    assert_same texture, result
    assert texture.dirty_field?(:parameters)
    assert_equal [
      3, 0, 0,
      0, 4, 0,
      0, 1.25, 1
    ], texture.matrix.elements
  end

  def test_accepts_custom_matrix
    matrix = Three::Matrix3.new.set(
      1, 0, 0.25,
      0, 1, 0.5,
      0, 0, 1
    )
    texture = Three::Texture.new("/texture.png", matrix_auto_update: false, matrix: matrix)

    assert_same matrix, texture.matrix
    refute texture.matrix_auto_update
  end

  def test_rejects_invalid_repeat_values
    error = assert_raises(TypeError) do
      Three::Texture.new("/texture.png", repeat: 2)
    end

    assert_match(/repeat must be/, error.message)
  end

  def test_rejects_invalid_matrix_values
    error = assert_raises(TypeError) do
      Three::Texture.new("/texture.png", matrix: [1, 2, 3])
    end

    assert_match(/matrix must be/, error.message)
  end

  def test_dispose_event
    texture = Three::Texture.new("/texture.png")
    called = false
    texture.on(:dispose) { called = true }

    texture.dispose

    assert called
  end

  def test_to_h
    texture = Three::Texture.new(
      "/texture.png",
      flip_y: false,
      wrap_s: Three::RepeatWrapping,
      wrap_t: Three::MirroredRepeatWrapping,
      mag_filter: Three::NearestFilter,
      min_filter: Three::NearestMipmapNearestFilter,
      offset: Three::Vector2.new(0.25, 0.5),
      repeat: Three::Vector2.new(2, 3),
      center: Three::Vector2.new(0.5, 0.5),
      rotation: Math::PI / 4,
      matrix_auto_update: false,
      matrix: Three::Matrix3.new.set(
        1, 0, 0.25,
        0, 1, 0.5,
        0, 0, 1
      )
    )

    assert_equal "Texture", texture.to_h[:type]
    assert_equal "/texture.png", texture.to_h[:source]
    refute texture.to_h[:flip_y]
    assert_equal Three::RepeatWrapping, texture.to_h[:wrap_s]
    assert_equal Three::MirroredRepeatWrapping, texture.to_h[:wrap_t]
    assert_equal Three::NearestFilter, texture.to_h[:mag_filter]
    assert_equal Three::NearestMipmapNearestFilter, texture.to_h[:min_filter]
    assert_equal [0.25, 0.5], texture.to_h[:offset]
    assert_equal [2, 3], texture.to_h[:repeat]
    assert_equal [0.5, 0.5], texture.to_h[:center]
    assert_equal Math::PI / 4, texture.to_h[:rotation]
    refute texture.to_h[:matrix_auto_update]
    assert_equal [
      1, 0, 0,
      0, 1, 0,
      0.25, 0.5, 1
    ], texture.to_h[:matrix]
  end
end
