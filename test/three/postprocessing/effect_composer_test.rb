# frozen_string_literal: true

require "test_helper"

class ThreePostprocessingEffectComposerTest < Minitest::Test
  def test_creates_composer_from_renderer
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)

    composer = Three::Postprocessing::EffectComposer.new(renderer: renderer)

    assert_equal :effect_composer, composer.handle[:type]
    assert_same renderer.handle, composer.handle[:renderer]
    assert_same backend, composer.backend
  end

  def test_composer_backend_must_match_renderer_backend
    renderer_backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: renderer_backend)
    foreign_backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)

    error = assert_raises(ArgumentError) do
      Three::Postprocessing::EffectComposer.new(renderer: renderer, backend: foreign_backend)
    end
    assert_equal "effect composer backend must match the renderer backend", error.message
  end

  def test_adds_postprocessing_passes
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    composer = Three::Postprocessing::EffectComposer.new(renderer: renderer)
    scene = Three::Scene.new
    camera = Three::PerspectiveCamera.new

    render_pass = Three::Postprocessing::RenderPass.new(scene, camera, composer: composer)
    bloom_pass = Three::Postprocessing::UnrealBloomPass.new(
      resolution: [640, 480],
      strength: 1.25,
      radius: 0.35,
      threshold: 0.18,
      composer: composer
    )
    output_pass = Three::Postprocessing::OutputPass.new(composer: composer)

    assert_same backend, render_pass.backend
    assert_same backend, bloom_pass.backend
    assert_same backend, output_pass.backend
    assert_equal :render_pass, render_pass.handle[:type]
    assert_equal :unreal_bloom_pass, bloom_pass.handle[:type]
    assert_equal :output_pass, output_pass.handle[:type]
    assert_equal [640, 480], bloom_pass.handle[:resolution]
    assert_equal 1.25, bloom_pass.strength
    assert output_pass.handle[:is_output_pass]

    assert_same composer, composer.add_pass(render_pass)
    assert_same composer, composer.add_pass(bloom_pass)
    assert_same composer, composer.add_pass(output_pass)

    assert_equal [render_pass, bloom_pass, output_pass], composer.passes
    assert_equal [render_pass.handle, bloom_pass.handle, output_pass.handle], composer.handle[:passes]
    assert_includes adapter.calls, [:effect_composer_add_pass, composer.handle, render_pass.handle]
    assert_includes adapter.calls, [:effect_composer_add_pass, composer.handle, bloom_pass.handle]
    assert_includes adapter.calls, [:effect_composer_add_pass, composer.handle, output_pass.handle]
  end

  def test_set_size_render_and_dispose_delegate_to_backend
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    composer = Three::Postprocessing::EffectComposer.new(renderer: renderer)
    scene = Three::Scene.new
    camera = Three::PerspectiveCamera.new
    mesh = Three::Mesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new)
    mesh.position.set(1, 2, 3)
    scene.add(mesh)

    assert_same composer, composer.set_size(800, 450)
    assert_equal [:effect_composer_set_size, composer.handle, 800, 450], adapter.calls.last
    assert_equal [800, 450], composer.handle[:size]

    assert_same composer, composer.render(scene, camera)
    assert_equal [:effect_composer_render, composer.handle], adapter.calls.last
    assert composer.handle[:rendered]
    assert_vector3_in_delta [1, 2, 3], mesh.get_world_position

    assert_same composer, composer.dispose
    assert_equal [:dispose_effect_composer, composer.handle], adapter.calls.last
    assert composer.handle[:disposed]
  end

  def test_pass_property_setters_sync_to_backend
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    scene = Three::Scene.new
    camera = Three::PerspectiveCamera.new
    render_pass = Three::Postprocessing::RenderPass.new(scene, camera, backend: backend)
    bloom_pass = Three::Postprocessing::UnrealBloomPass.new(backend: backend)
    output_pass = Three::Postprocessing::OutputPass.new(backend: backend)

    render_pass.enabled = false
    bloom_pass.strength = 1.8
    bloom_pass.radius = 0.45
    bloom_pass.threshold = 0.22
    output_pass.enabled = false

    assert_includes adapter.calls, [:set_postprocessing_pass_property, render_pass.handle, "enabled", false]
    assert_includes adapter.calls, [:set_postprocessing_pass_property, bloom_pass.handle, "strength", 1.8]
    assert_includes adapter.calls, [:set_postprocessing_pass_property, bloom_pass.handle, "radius", 0.45]
    assert_includes adapter.calls, [:set_postprocessing_pass_property, bloom_pass.handle, "threshold", 0.22]
    assert_includes adapter.calls, [:set_postprocessing_pass_property, output_pass.handle, "enabled", false]
    refute render_pass.handle[:enabled]
    refute output_pass.handle[:enabled]
    assert_equal 1.8, bloom_pass.handle[:strength]
    assert_equal 0.45, bloom_pass.handle[:radius]
    assert_equal 0.22, bloom_pass.handle[:threshold]
  end

  def test_add_pass_requires_matching_backend
    renderer_backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: renderer_backend)
    composer = Three::Postprocessing::EffectComposer.new(renderer: renderer)
    foreign_backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    render_pass = Three::Postprocessing::RenderPass.new(Three::Scene.new, Three::PerspectiveCamera.new, backend: foreign_backend)

    error = assert_raises(ArgumentError) { composer.add_pass(render_pass) }
    assert_equal "postprocessing pass must use the same backend as the composer", error.message
  end

  def test_unreal_bloom_pass_requires_array_like_resolution
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)

    assert_raises(TypeError) do
      Three::Postprocessing::UnrealBloomPass.new(resolution: 1, backend: backend)
    end

    assert_raises(TypeError) do
      Three::Postprocessing::UnrealBloomPass.new(resolution: [1, 2, 3], backend: backend)
    end
  end
end
