# frozen_string_literal: true

require "test_helper"

class ThreeVersionTest < Minitest::Test
  def test_version_is_defined
    refute_nil Three::VERSION
  end
end
