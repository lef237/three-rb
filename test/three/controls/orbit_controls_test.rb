# frozen_string_literal: true

require "test_helper"

class ThreeOrbitControlsTest < Minitest::Test
  def test_creates_controls_from_renderer_dom_element
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    camera = Three::PerspectiveCamera.new

    controls = Three::Controls::OrbitControls.new(camera, renderer: renderer)

    assert_equal :orbit_controls, controls.handle[:type]
    assert_equal :perspective_camera, controls.handle[:camera][:type]
    assert_same renderer.dom_element, controls.handle[:dom_element]
  end

  def test_applies_options
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    camera = Three::PerspectiveCamera.new

    controls = Three::Controls::OrbitControls.new(camera, renderer: renderer, enable_damping: true, damping_factor: 0.12, enable_pan: false)

    assert controls.enable_damping
    assert_equal 0.12, controls.damping_factor
    refute controls.enable_pan
    assert_includes adapter.calls, [:set_control_property, controls.handle, "enableDamping", true]
    assert_includes adapter.calls, [:set_control_property, controls.handle, "dampingFactor", 0.12]
    assert_includes adapter.calls, [:set_control_property, controls.handle, "enablePan", false]
  end

  def test_syncs_target_changes
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    controls = Three::Controls::OrbitControls.new(Three::PerspectiveCamera.new, renderer: renderer)

    controls.target.set(1, 2, 3)

    assert_equal [:set_orbit_controls_target, controls.handle, [1, 2, 3]], adapter.calls.last
  end

  def test_update_and_dispose_delegate
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    controls = Three::Controls::OrbitControls.new(Three::PerspectiveCamera.new, renderer: renderer)

    assert_same controls, controls.update
    assert_includes adapter.calls, [:update_controls, controls.handle]

    assert_same controls, controls.dispose
    assert_equal [:dispose_controls, controls.handle], adapter.calls.last
  end

  def test_update_pulls_controlled_object_transform_back_to_ruby
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    camera = Three::PerspectiveCamera.new
    controls = Three::Controls::OrbitControls.new(camera, renderer: renderer)

    controls.handle[:camera][:position] = [1, 2, 3]
    controls.handle[:camera][:quaternion] = [0, 0.70710678, 0, 0.70710678]
    controls.handle[:camera][:scale] = [1, 1, 1]

    controls.update

    assert_vector3_in_delta [1, 2, 3], camera.position
    assert_quaternion_in_delta [0, 0.70710678, 0, 0.70710678], camera.quaternion
    refute camera.dirty_field?(:transform)
  end
end
