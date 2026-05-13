# frozen_string_literal: true

require "test_helper"

class ThreeBrowserCubeExampleTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  EXAMPLE_DIR = File.join(ROOT, "examples/browser/cube")

  def test_browser_cube_example_files_exist
    assert_path_exists File.join(EXAMPLE_DIR, "index.html")
    assert_path_exists File.join(EXAMPLE_DIR, "main.rb")
    assert_path_exists File.join(EXAMPLE_DIR, "README.md")
  end

  def test_index_loads_pinned_browser_dependencies
    html = File.read(File.join(EXAMPLE_DIR, "index.html"))

    assert_includes html, "three@0.184.0"
    assert_includes html, "@ruby/3.4-wasm-wasi@2.9.4"
    assert_includes html, "data-eval=\"async\""
    assert_includes html, "globalThis.THREE"
  end

  def test_main_uses_three_rb_renderer
    ruby = File.read(File.join(EXAMPLE_DIR, "main.rb"))

    assert_includes ruby, "require_relative \"../../../lib/three\""
    assert_includes ruby, "Three::Renderers::ThreeJSRenderer"
    assert_includes ruby, "renderer.animation_loop"
    assert_includes ruby, "renderer.render(scene, camera)"
  end
end
