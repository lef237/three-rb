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

def set_instance_grid(instanced_mesh, matrix, instance_count, columns, rows, phase = 0.0)
  instance_count.times do |index|
    column = index % columns
    row = index / columns
    x = (column - ((columns - 1) / 2.0)) * 0.145
    y = (row - ((rows - 1) / 2.0)) * 0.145
    z = Math.sin(index * 0.017 + phase) * 0.08
    instanced_mesh.set_matrix_at(index, matrix.make_translation(x, y, z))
  end
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
  status[:textContent] = "Building 1000 InstancedMesh scene"

  instance_count = 1000
  columns = 40
  rows = (instance_count.to_f / columns).ceil
  iterations = 30

  scene = Three::Scene.new
  camera = Three::PerspectiveCamera.new(45, aspect: 1.0, near: 0.1, far: 100)
  camera.position.z = 7.5

  geometry = Three::BoxGeometry.new(0.055, 0.055, 0.055)
  material = Three::MeshBasicMaterial.new(color: 0x66d9b8)
  instanced_mesh = Three::InstancedMesh.new(geometry, material, instance_count)
  matrix = Three::Matrix4.new
  set_instance_grid(instanced_mesh, matrix, instance_count, columns, rows)
  scene.add(instanced_mesh)

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
  dirty_object = measure.call("dirty_object_transform_sync", iterations) do |frame|
    instanced_mesh.rotation.z += 0.004
    instanced_mesh.position.z = Math.sin(frame * 0.1) * 0.08
  end
  dirty_instances = measure.call("dirty_instance_matrix_sync", iterations) do |frame|
    set_instance_grid(instanced_mesh, matrix, instance_count, columns, rows, frame * 0.03)
  end

  renderer.render(scene, camera)
  JS.global[:__threeRbRenderer] = renderer.handle
  JS.global[:__threeRbInstancedMeshSyncScene] = renderer.backend.materialize(scene)
  JS.global[:__threeRbInstancedMeshSyncCamera] = renderer.backend.materialize(camera)
  instanced_mesh_handle = renderer.backend.materialize(instanced_mesh)
  JS.global[:__threeRbInstancedMeshSyncMesh] = instanced_mesh_handle

  result = {
    benchmark: "browser_instanced_mesh_sync",
    instance_count: instance_count,
    iterations: iterations,
    initial_sync_ms: round_ms(initial_sync_ms),
    clean_sync: clean,
    dirty_object_transform_sync: dirty_object,
    dirty_instance_matrix_sync: dirty_instances,
    backend_handle_count: renderer.backend.handles.length,
    first_mesh_instanced: instanced_mesh_handle[:isInstancedMesh] == JS::True,
    first_mesh_type: instanced_mesh_handle[:type].to_s
  }

  json = JSON.pretty_generate(result)
  JS.global[:__threeRbInstancedMeshSyncBenchmarkJson] = json
  result_node[:textContent] = json
  status[:textContent] = "Benchmark complete"
  status_dot[:dataset][:state] = "running"
rescue StandardError => error
  JS.global.call(:__threeRbBootFailed, error.message) if JS.global[:__threeRbBootFailed]
  raise
end
