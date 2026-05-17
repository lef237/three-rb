# frozen_string_literal: true

require "test_helper"

class ThreeSceneTest < Minitest::Test
  def test_type_and_scene_state
    scene = Three::Scene.new

    assert_equal "Scene", scene.type
    assert_nil scene.background
    assert_nil scene.environment
    assert_nil scene.fog
    assert_nil scene.override_material
  end

  def test_marks_dirty_when_scene_resources_change
    scene = Three::Scene.new
    scene.mark_clean!
    texture = Three::CubeTexture.new(%w[/px.png /nx.png /py.png /ny.png /pz.png /nz.png])
    fog = Three::Fog.new(0x112233, near: 1, far: 20)
    material = Three::MeshBasicMaterial.new(color: 0xff0000)

    scene.background = texture
    scene.environment = texture
    scene.fog = fog
    scene.override_material = material

    assert scene.dirty_field?(:scene)
  end

  def test_marks_dirty_when_attached_scene_resource_changes
    scene = Three::Scene.new
    fog = Three::Fog.new
    scene.fog = fog
    scene.mark_clean!
    fog.mark_clean!

    fog.near = 2

    assert fog.dirty_field?(:parameters)
    assert scene.dirty_field?(:resources)
  end
end
