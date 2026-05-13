# frozen_string_literal: true

require "test_helper"

class ThreeAnimationMixerTest < Minitest::Test
  def test_creates_mixer_for_external_root_and_clip_action
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    root = Three::ExternalObject3D.new({ type: :gltf_scene, children: [] }, type: "GLTFScene")
    clip = Three::AnimationClip.new({ type: :animation_clip, name: "Spin", duration: 1.5 }, adapter: adapter)

    mixer = Three::AnimationMixer.new(root, backend: backend)
    action = mixer.clip_action(clip)

    assert_equal :animation_mixer, mixer.handle[:type]
    assert_same root.handle, mixer.handle[:root]
    assert_equal :animation_action, action.handle[:type]
    assert_same clip.handle, action.handle[:clip]
  end

  def test_updates_and_stops_mixer
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    root = Three::ExternalObject3D.new({ type: :gltf_scene, children: [] }, type: "GLTFScene")
    mixer = Three::AnimationMixer.new(root, backend: backend)

    assert_same mixer, mixer.update(0.25)
    assert_same mixer, mixer.stop_all_action
    assert_same mixer, mixer.uncache_root

    assert_includes adapter.calls, [:update_animation_mixer, mixer.handle, 0.25]
    assert_includes adapter.calls, [:stop_all_animation_actions, mixer.handle]
    assert_includes adapter.calls, [:uncache_animation_root, mixer.handle, root.handle]
  end

  def test_action_delegates_playback_and_properties
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    root = Three::ExternalObject3D.new({ type: :gltf_scene, children: [] }, type: "GLTFScene")
    clip = Three::AnimationClip.new({ type: :animation_clip, name: "Spin", duration: 1.5 }, adapter: adapter)
    action = Three::AnimationMixer.new(root, backend: backend).clip_action(clip)

    action.time_scale = 0.5
    action.weight = 0.8
    action.clamp_when_finished = true
    assert_same action, action.reset
    assert_same action, action.fade_in(0.2)
    assert_same action, action.play
    assert_same action, action.fade_out(0.1)
    assert_same action, action.stop

    assert_includes adapter.calls, [:set_animation_action_property, action.handle, "timeScale", 0.5]
    assert_includes adapter.calls, [:set_animation_action_property, action.handle, "weight", 0.8]
    assert_includes adapter.calls, [:set_animation_action_property, action.handle, "clampWhenFinished", true]
    assert_includes adapter.calls, [:reset_animation_action, action.handle]
    assert_includes adapter.calls, [:fade_in_animation_action, action.handle, 0.2]
    assert_includes adapter.calls, [:play_animation_action, action.handle]
    assert_includes adapter.calls, [:fade_out_animation_action, action.handle, 0.1]
    assert_includes adapter.calls, [:stop_animation_action, action.handle]
  end

  def test_animation_clip_reads_name_and_duration
    adapter = FakeThreeJSAdapter.new
    clip = Three::AnimationClip.new({ type: :animation_clip, name: "Spin", duration: 1.5 }, adapter: adapter)

    assert_equal "Spin", clip.name
    assert_equal 1.5, clip.duration
  end
end
