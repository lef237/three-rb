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

  def test_set_clear_color_delegates
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)

    assert_same renderer, renderer.set_clear_color(0x101418, 1)
    assert_equal [:set_clear_color, renderer.handle, 0x101418, 1], adapter.calls.last
  end

  def test_configures_shadow_map_from_initializer_and_method
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(
      backend: backend,
      shadow_map_enabled: true,
      shadow_map_type: Three::PCFShadowMap
    )

    assert_equal({ enabled: true, type: Three::PCFShadowMap }, renderer.handle[:shadow_map])

    assert_same renderer, renderer.configure_shadow_map(type: Three::VSMShadowMap, auto_update: false)
    assert_equal({ enabled: true, type: Three::VSMShadowMap, auto_update: false }, renderer.handle[:shadow_map])
    assert_equal :set_renderer_shadow_map, adapter.calls.last[0]
  end

  def test_dom_element_delegates_to_backend
    backend = Three::Backends::ThreeJS.new(adapter: FakeThreeJSAdapter.new)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)

    assert_equal :dom_element, renderer.dom_element[:type]
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

  def test_render_does_not_resync_clean_transforms
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    scene = Three::Scene.new
    camera = Three::PerspectiveCamera.new
    mesh = Three::Mesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new)
    scene.add(mesh)

    renderer.render(scene, camera)
    adapter.calls.clear
    renderer.render(scene, camera)

    assert_equal :render, adapter.calls.last[0]
    refute adapter.calls.any? { |call| call[0] == :set_object_transform }
  end

  def test_dispose_delegates_to_backend
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    texture = Three::Texture.new("/texture.png")
    material = Three::MeshBasicMaterial.new(map: texture)

    material_handle = backend.materialize(material)
    texture_handle = backend.materialize(texture)
    adapter.calls.clear

    assert_same renderer, renderer.dispose(material, dispose_textures: true)
    assert_equal [
      [:dispose, texture_handle],
      [:dispose, material_handle]
    ], adapter.calls
  end

  def test_on_dispose_registers_backend_dispose_listener
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    material = Three::MeshBasicMaterial.new
    callback = proc {}

    assert_same renderer, renderer.on_dispose(material, &callback)

    assert_equal [:add_event_listener, backend.materialize(material), :dispose, callback], adapter.calls.last
  end

  def test_cached_reports_backend_handle_cache
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    material = Three::MeshBasicMaterial.new

    refute renderer.cached?(material)
    backend.materialize(material)
    assert renderer.cached?(material)
  end

  def test_traverse_handles_delegates_to_backend
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    external = Three::ExternalObject3D.new({ type: :gltf_scene, children: [{ type: :loaded_mesh, children: [] }] }, type: "GLTFScene")
    visited = []

    assert_same renderer, renderer.traverse_handles(external) { |node| visited << node[:type] }
    assert_equal %i[gltf_scene loaded_mesh], visited
  end

  def test_dispose_subtree_defaults_to_texture_cleanup
    adapter = FakeThreeJSAdapter.new
    backend = Three::Backends::ThreeJS.new(adapter: adapter)
    renderer = Three::Renderers::ThreeJSRenderer.new(backend: backend)
    texture = { type: :loaded_texture }
    material = { type: :loaded_material, map: texture }
    mesh = { type: :loaded_mesh, material: material, children: [] }
    external = Three::ExternalObject3D.new({ type: :gltf_scene, children: [mesh] }, type: "GLTFScene")

    assert_same renderer, renderer.dispose_subtree(external)
    assert_equal [
      [:dispose, material],
      [:dispose, texture]
    ], adapter.calls
  end
end
