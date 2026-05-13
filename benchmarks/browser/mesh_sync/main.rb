# frozen_string_literal: true

require "js"
require "json"

def summarize(label, samples)
  sorted = samples.sort
  {
    label: label,
    min_ms: round_ms(sorted.first),
    max_ms: round_ms(sorted.last),
    avg_ms: round_ms(samples.sum / samples.length),
    p95_ms: round_ms(sorted[(samples.length * 0.95).floor.clamp(0, samples.length - 1)])
  }
end

def round_ms(value)
  (value.to_f * 1000).round / 1000.0
end

begin
  JS.global[:__threeReady].await

  require_relative "../../../lib/three"

  document = JS.global[:document]
  window = JS.global[:window]
  performance = JS.global[:performance]
  viewport = document.call(:querySelector, "#viewport")
  status = document.call(:querySelector, "#status")
  status_dot = document.call(:querySelector, "#status-dot")
  result_node = document.call(:querySelector, "#result")
  status[:textContent] = "Building 1000 Mesh scene"

  mesh_count = 1000
  columns = 40
  rows = (mesh_count.to_f / columns).ceil
  iterations = 30

  scene = Three::Scene.new
  camera = Three::PerspectiveCamera.new(45, aspect: 1.0, near: 0.1, far: 100)
  camera.position.z = 7.5

  geometry = Three::BoxGeometry.new(0.055, 0.055, 0.055)
  material = Three::MeshBasicMaterial.new(color: 0x66d9b8)
  meshes = []

  mesh_count.times do |index|
    column = index % columns
    row = index / columns
    mesh = Three::Mesh.new(geometry, material)
    mesh.position.set(
      (column - ((columns - 1) / 2.0)) * 0.145,
      (row - ((rows - 1) / 2.0)) * 0.145,
      ((index % 9) - 4) * 0.01
    )
    scene.add(mesh)
    meshes << mesh
  end

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: false,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x101418, 1)

  resize = proc do
    width = [viewport[:clientWidth].to_i, 1].max
    height = [viewport[:clientHeight].to_i, 1].max

    camera.aspect = width.to_f / height
    camera.update_projection_matrix
    renderer.set_size(width, height)
  end
  resize.call
  window.call(:addEventListener, "resize", resize)

  sync_scene = proc do
    scene.update_matrix_world
    camera.update_matrix_world if camera.parent.nil?
    renderer.backend.sync(scene)
    renderer.backend.sync(camera)
  end

  now = proc { performance.call(:now).to_f }
  measure = proc do |label, count, &block|
    samples = []
    count.times do |index|
      block.call(index) if block
      started_at = now.call
      sync_scene.call
      samples << (now.call - started_at)
    end
    summarize(label, samples)
  end

  started_at = now.call
  sync_scene.call
  initial_sync_ms = now.call - started_at

  clean = measure.call("clean_sync", iterations)
  dirty = measure.call("dirty_transform_sync", iterations) do |frame|
    offset = frame * 0.001
    meshes.each_with_index do |mesh, index|
      mesh.rotation.z += 0.004
      mesh.position.z = Math.sin(index * 0.017 + offset) * 0.08
    end
  end

  renderer.render(scene, camera)
  JS.global[:__threeRbRenderer] = renderer.handle
  JS.global[:__threeRbMeshSyncScene] = renderer.backend.materialize(scene)
  JS.global[:__threeRbMeshSyncCamera] = renderer.backend.materialize(camera)
  first_mesh_handle = renderer.backend.materialize(meshes.first)
  JS.global[:__threeRbMeshSyncFirstMesh] = first_mesh_handle

  result = {
    benchmark: "browser_mesh_sync",
    mesh_count: mesh_count,
    iterations: iterations,
    initial_sync_ms: round_ms(initial_sync_ms),
    clean_sync: clean,
    dirty_transform_sync: dirty,
    backend_handle_count: renderer.backend.handles.length,
    first_mesh_type: first_mesh_handle[:type].to_s
  }

  json = JSON.pretty_generate(result)
  JS.global[:__threeRbMeshSyncBenchmarkJson] = json
  result_node[:textContent] = json
  status[:textContent] = "Benchmark complete"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
