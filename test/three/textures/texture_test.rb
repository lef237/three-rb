# frozen_string_literal: true

require "test_helper"

class ThreeTextureTest < Minitest::Test
  def test_defaults
    texture = Three::Texture.new("/texture.png")

    assert_equal "/texture.png", texture.source
    assert texture.flip_y
    assert texture.uuid
  end

  def test_marks_dirty_when_source_changes
    texture = Three::Texture.new("/texture.png")
    texture.mark_clean!

    texture.source = "/other.png"

    assert texture.dirty_field?(:parameters)
  end

  def test_to_h
    texture = Three::Texture.new("/texture.png", flip_y: false)

    assert_equal "Texture", texture.to_h[:type]
    assert_equal "/texture.png", texture.to_h[:source]
    refute texture.to_h[:flip_y]
  end
end
