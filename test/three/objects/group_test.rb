# frozen_string_literal: true

require "test_helper"

class ThreeGroupTest < Minitest::Test
  def test_type
    assert_equal "Group", Three::Group.new.type
  end
end
