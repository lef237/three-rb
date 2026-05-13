# frozen_string_literal: true

require "test_helper"

class ThreeThreeJSRendererTest < Minitest::Test
  def test_creates_renderer_and_sets_size
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(canvas: "#canvas", backend: backend, antialias: true)

    renderer.set_size(800, 600)

    assert_equal :renderer, renderer.handle[:type]
    assert_equal({ canvas: "#canvas", antialias: true }, renderer.handle[:options])
    assert_equal [:set_renderer_size, renderer.handle, 800, 600], adapter.calls.last
  end

  def test_animation_loop_delegates
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    callback = proc {}

    renderer.animation_loop(&callback)

    assert_equal [:set_animation_loop, renderer.handle, callback], adapter.calls.last
  end

  def test_render_updates_matrices_and_delegates
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    scene = Three::Scene.new
    camera = Three::PerspectiveCamera.new
    mesh = Three::Mesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new)
    mesh.position.set(1, 2, 3)
    scene.add(mesh)

    renderer.render(scene, camera)

    assert_equal :render, adapter.calls.last[0]
    assert_vector3_in_delta [1, 2, 3], mesh.get_world_position
  end
end
