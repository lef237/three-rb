# frozen_string_literal: true

require "test_helper"

class ThreeSceneTest < Minitest::Test
  def test_type_and_scene_state
    scene = Three::Scene.new

    assert_equal "Scene", scene.type
    assert_nil scene.background
    assert_nil scene.environment
  end
end
