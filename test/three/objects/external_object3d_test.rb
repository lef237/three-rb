# frozen_string_literal: true

require "test_helper"

class ThreeExternalObject3DTest < Minitest::Test
  def test_wraps_existing_backend_handle
    handle = { type: :gltf_scene }
    object = Three::ExternalObject3D.new(handle, type: "GLTFScene")

    assert_same handle, object.handle
    assert_equal "GLTFScene", object.type
    refute object.dirty?
  end

  def test_can_be_added_to_a_scene
    scene = Three::Scene.new
    object = Three::ExternalObject3D.new({ type: :gltf_scene }, type: "GLTFScene")

    scene.add(object)

    assert_same scene, object.parent
    assert_includes scene.children, object
    assert object.dirty_field?(:transform)
  end
end
