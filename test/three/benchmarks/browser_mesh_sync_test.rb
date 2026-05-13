# frozen_string_literal: true

require "test_helper"
require "json"

class ThreeBrowserMeshSyncBenchmarkTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  BENCHMARK_DIR = File.join(ROOT, "benchmarks/browser/mesh_sync")
  INSTANCED_BENCHMARK_DIR = File.join(ROOT, "benchmarks/browser/instanced_mesh_sync")

  def test_browser_mesh_sync_benchmark_files_exist
    assert_path_exists File.join(BENCHMARK_DIR, "index.html")
    assert_path_exists File.join(BENCHMARK_DIR, "boot.mjs")
    assert_path_exists File.join(BENCHMARK_DIR, "main.rb")
    assert_path_exists File.join(BENCHMARK_DIR, "run.mjs")
    assert_path_exists File.join(BENCHMARK_DIR, "README.md")
  end

  def test_browser_instanced_mesh_sync_benchmark_files_exist
    assert_path_exists File.join(INSTANCED_BENCHMARK_DIR, "index.html")
    assert_path_exists File.join(INSTANCED_BENCHMARK_DIR, "boot.mjs")
    assert_path_exists File.join(INSTANCED_BENCHMARK_DIR, "main.rb")
    assert_path_exists File.join(INSTANCED_BENCHMARK_DIR, "run.mjs")
    assert_path_exists File.join(INSTANCED_BENCHMARK_DIR, "README.md")
  end

  def test_browser_mesh_sync_benchmark_exercises_1000_individual_meshes
    ruby = File.read(File.join(BENCHMARK_DIR, "main.rb"))

    assert_includes ruby, "mesh_count = 1000"
    assert_includes ruby, "Three::Mesh.new"
    assert_includes ruby, "renderer.backend.sync(scene)"
    assert_includes ruby, "dirty_transform_sync"
    refute_includes ruby, "Three::InstancedMesh"
  end

  def test_browser_instanced_mesh_sync_benchmark_exercises_1000_instances
    ruby = File.read(File.join(INSTANCED_BENCHMARK_DIR, "main.rb"))

    assert_includes ruby, "instance_count = 1000"
    assert_includes ruby, "Three::InstancedMesh.new"
    assert_includes ruby, "renderer.backend.sync(scene)"
    assert_includes ruby, "dirty_object_transform_sync"
    assert_includes ruby, "dirty_instance_matrix_sync"
    refute_includes ruby, "Three::Mesh.new"
  end

  def test_package_script_runs_browser_mesh_sync_benchmark
    package = JSON.parse(File.read(File.join(ROOT, "package.json")))

    assert_equal "pnpm benchmark:browser:mesh-sync && pnpm benchmark:browser:instanced-mesh-sync", package.fetch("scripts").fetch("benchmark:browser")
    assert_equal "node benchmarks/browser/mesh_sync/run.mjs", package.fetch("scripts").fetch("benchmark:browser:mesh-sync")
    assert_equal "node benchmarks/browser/instanced_mesh_sync/run.mjs", package.fetch("scripts").fetch("benchmark:browser:instanced-mesh-sync")
  end
end
