# frozen_string_literal: true

require "test_helper"

class ThreeCubeTextureTest < Minitest::Test
  SOURCES = %w[
    /px.png
    /nx.png
    /py.png
    /ny.png
    /pz.png
    /nz.png
  ].freeze

  def test_defaults
    texture = Three::CubeTexture.new(SOURCES)

    assert_equal SOURCES, texture.sources
    assert_equal SOURCES, texture.source
    refute texture.flip_y
    assert_equal Three::ClampToEdgeWrapping, texture.wrap_s
    assert_equal Three::ClampToEdgeWrapping, texture.wrap_t
    assert_equal Three::LinearFilter, texture.mag_filter
    assert_equal Three::LinearMipmapLinearFilter, texture.min_filter
    assert_equal [1, 1], texture.repeat.to_a
    assert texture.uuid
  end

  def test_rejects_source_sets_without_six_faces
    error = assert_raises(ArgumentError) do
      Three::CubeTexture.new(["/px.png"])
    end

    assert_match(/six image sources/, error.message)
  end

  def test_marks_dirty_when_sources_change
    texture = Three::CubeTexture.new(SOURCES)
    texture.mark_clean!

    texture.sources = SOURCES.map { |source| source.sub(".png", "-2.png") }

    assert texture.dirty_field?(:parameters)
  end

  def test_to_h
    texture = Three::CubeTexture.new(
      SOURCES,
      wrap_s: Three::RepeatWrapping,
      wrap_t: Three::MirroredRepeatWrapping,
      mag_filter: Three::NearestFilter,
      min_filter: Three::NearestMipmapNearestFilter,
      repeat: [2, 3]
    )

    assert_equal "CubeTexture", texture.to_h[:type]
    assert_equal SOURCES, texture.to_h[:source]
    assert_equal SOURCES, texture.to_h[:sources]
    assert_equal Three::RepeatWrapping, texture.to_h[:wrap_s]
    assert_equal Three::MirroredRepeatWrapping, texture.to_h[:wrap_t]
    assert_equal Three::NearestFilter, texture.to_h[:mag_filter]
    assert_equal Three::NearestMipmapNearestFilter, texture.to_h[:min_filter]
    assert_equal [2, 3], texture.to_h[:repeat]
  end
end
