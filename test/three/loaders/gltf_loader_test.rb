# frozen_string_literal: true

require "test_helper"

class ThreeGLTFLoaderTest < Minitest::Test
  def test_load_returns_gltf_with_external_scene
    adapter = FakeThreeJSAdapter.new

    gltf = Three::Loaders::GLTFLoader.new(adapter: adapter).load("/model.gltf")

    assert_instance_of Three::Loaders::GLTF, gltf
    assert_equal "/model.gltf", gltf.handle[:source]
    assert_instance_of Three::ExternalObject3D, gltf.scene
    assert_equal "GLTFScene", gltf.scene.type
    assert_same gltf.handle[:scene], gltf.scene.handle
    assert_equal 1, gltf.animations.length
    assert_instance_of Three::AnimationClip, gltf.animations.first
    assert_equal "Spin", gltf.animations.first.name
    assert_equal 1.5, gltf.animations.first.duration
  end

  def test_load_yields_gltf
    adapter = FakeThreeJSAdapter.new
    yielded = nil

    gltf = Three::Loaders::GLTFLoader.new(adapter: adapter).load("/model.gltf") { |loaded| yielded = loaded }

    assert_same gltf, yielded
  end
end
