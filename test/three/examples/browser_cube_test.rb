# frozen_string_literal: true

require "test_helper"
require "json"

class ThreeBrowserCubeExampleTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  EXAMPLE_DIR = File.join(ROOT, "examples/browser/cube")
  COMPOSITION_EXAMPLE_DIR = File.join(ROOT, "examples/browser/composition")

  def test_browser_cube_example_files_exist
    assert_path_exists File.join(EXAMPLE_DIR, "index.html")
    assert_path_exists File.join(EXAMPLE_DIR, "main.rb")
    assert_path_exists File.join(EXAMPLE_DIR, "README.md")
    assert_path_exists File.join(EXAMPLE_DIR, "smoke_test.mjs")
  end

  def test_browser_composition_example_files_exist
    assert_path_exists File.join(COMPOSITION_EXAMPLE_DIR, "index.html")
    assert_path_exists File.join(COMPOSITION_EXAMPLE_DIR, "main.rb")
    assert_path_exists File.join(COMPOSITION_EXAMPLE_DIR, "README.md")
    assert_path_exists File.join(COMPOSITION_EXAMPLE_DIR, "smoke_test.mjs")
  end

  def test_index_loads_pinned_browser_dependencies
    html = File.read(File.join(EXAMPLE_DIR, "index.html"))

    assert_includes html, "/node_modules/three/build/three.module.js"
    assert_includes html, "/node_modules/three/examples/jsm/"
    assert_includes html, "/node_modules/@bjorn3/browser_wasi_shim/dist/index.js"
    assert_includes html, "/node_modules/@ruby/wasm-wasi/dist/esm/browser.js"
    assert_includes html, "./boot.mjs"
    assert_includes html, "data-testid=\"status\""
    assert_includes html, "data-testid=\"scene-canvas\""
  end

  def test_main_uses_three_rb_renderer
    ruby = File.read(File.join(EXAMPLE_DIR, "main.rb"))

    assert_includes ruby, "require_relative \"../../../lib/three\""
    assert_includes ruby, "Three::Renderers::ThreeJSRenderer"
    assert_includes ruby, "renderer.animation_loop"
    assert_includes ruby, "renderer.render(scene, camera)"
    assert_includes ruby, "preserveDrawingBuffer: true"
  end

  def test_composition_example_exercises_plane_grouping_and_material_updates
    ruby = File.read(File.join(COMPOSITION_EXAMPLE_DIR, "main.rb"))

    assert_includes ruby, "Three::PlaneGeometry"
    assert_includes ruby, "Three::SphereGeometry"
    assert_includes ruby, "Three::MeshNormalMaterial"
    assert_includes ruby, "Three::Loaders::TextureLoader"
    assert_includes ruby, "Three::Controls::OrbitControls"
    assert_includes ruby, "Three::Group"
    assert_includes ruby, "rig.add(primary)"
    assert_includes ruby, "rig.add(satellite)"
    assert_includes ruby, "primary_material.color.set_rgb"
    assert_includes ruby, "renderer.animation_loop"
  end

  def test_package_script_runs_browser_smoke_test
    package = JSON.parse(File.read(File.join(ROOT, "package.json")))

    assert_match(/\Apnpm@/, package.fetch("packageManager"))
    assert_equal "0.4.2", package.fetch("dependencies").fetch("@bjorn3/browser_wasi_shim")
    assert_equal "2.9.4-2026-05-11-a", package.fetch("dependencies").fetch("@ruby/3.4-wasm-wasi")
    assert_equal "2.9.4-2026-05-11-a", package.fetch("dependencies").fetch("@ruby/wasm-wasi")
    assert_equal "0.184.0", package.fetch("dependencies").fetch("three")
    assert_equal "pnpm test:browser:cube && pnpm test:browser:composition", package.fetch("scripts").fetch("test:browser")
    assert_equal "node examples/browser/cube/smoke_test.mjs", package.fetch("scripts").fetch("test:browser:cube")
    assert_equal "node examples/browser/composition/smoke_test.mjs", package.fetch("scripts").fetch("test:browser:composition")
    assert_includes package.fetch("devDependencies"), "playwright"
  end
end
