# frozen_string_literal: true

require "test_helper"

class ThreeSceneTest < Minitest::Test
  def test_type_and_scene_state
    scene = Three::Scene.new

    assert_equal "Scene", scene.type
    assert_nil scene.background
    assert_nil scene.environment
  end

  def test_marks_dirty_when_background_or_environment_changes
    scene = Three::Scene.new
    scene.mark_clean!
    texture = Three::CubeTexture.new(%w[/px.png /nx.png /py.png /ny.png /pz.png /nz.png])

    scene.background = texture
    scene.environment = texture

    assert scene.dirty_field?(:scene)
  end
end
