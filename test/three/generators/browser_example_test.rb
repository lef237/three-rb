# frozen_string_literal: true

require "test_helper"
require "stringio"
require "tmpdir"
require "three/generators/browser_example"

class ThreeBrowserExampleGeneratorTest < Minitest::Test
  def test_generates_ruby_only_standalone_browser_example
    Dir.mktmpdir("three-rb-browser-generator") do |dir|
      stream = StringIO.new

      generator = Three::Generators::BrowserExample.new(
        target: "examples/browser/quickstart",
        root: dir,
        stream: stream
      ).call

      main = File.read(File.join(dir, "examples/browser/quickstart/main.rb"))
      boot = File.read(File.join(dir, "examples/browser/quickstart/boot.mjs"))
      index = File.read(File.join(dir, "examples/browser/quickstart/index.html"))

      assert_includes generator.created, "examples/browser/quickstart/main.rb"
      assert_path_exists File.join(dir, "lib/three.rb")
      assert_path_exists File.join(dir, "examples/browser/shared/boot.mjs")
      assert_path_exists File.join(dir, "package.json")
      assert_path_exists File.join(dir, "pnpm-lock.yaml")
      assert_includes main, "require_relative \"../../../lib/three\""
      assert_includes main, "Three::BoxGeometry"
      assert_includes main, "Three::Browser.run"
      assert_includes main, "app.resize_renderer(renderer, camera)"
      assert_includes main, "app.animation_loop(renderer)"
      refute_includes main, "faceted_ruby_geometry"
      refute_includes main, "require \"js\""
      refute_includes main, "JS.global"
      assert_includes boot, "import { bootRubyExample } from \"../shared/boot.mjs\""
      assert_includes boot, "main: \"examples/browser/quickstart/main\""
      assert_includes index, "data-testid=\"scene-canvas\""
      assert_includes stream.string, "Created browser example at examples/browser/quickstart"
    end
  end

  def test_generates_ruby_browser_example_with_local_assets
    Dir.mktmpdir("three-rb-browser-generator") do |dir|
      stream = StringIO.new

      generator = Three::Generators::BrowserExample.new(
        target: "examples/browser/ruby",
        root: dir,
        stream: stream
      ).call

      main = File.read(File.join(dir, "examples/browser/ruby/main.rb"))
      boot = File.read(File.join(dir, "examples/browser/ruby/boot.mjs"))
      readme = File.read(File.join(dir, "examples/browser/ruby/README.md"))

      assert_includes generator.created, "examples/browser/ruby/main.rb"
      assert_includes generator.created, "examples/browser/ruby/assets/studio.hdr"
      assert_path_exists File.join(dir, "examples/browser/ruby/assets/studio.hdr")
      assert_path_exists File.join(dir, "examples/browser/shared/boot.mjs")
      assert_includes main, "faceted_ruby_geometry"
      assert_includes main, "/examples/browser/ruby/assets/studio.hdr"
      assert_includes main, "Three::Loaders::RGBELoader"
      assert_includes main, "Three::TextGeometry"
      assert_includes main, "Three::Controls::OrbitControls"
      assert_includes main, "require_relative \"../../../lib/three\""
      refute_includes main, "/examples/browser/assets/"
      refute_includes main, "require \"js\""
      refute_includes main, "JS.global"
      assert_includes boot, "main: \"examples/browser/ruby/main\""
      assert_includes readme, "local `assets/` directory"
      assert_includes stream.string, "Created browser example at examples/browser/ruby"
    end
  end

  def test_skips_existing_runtime_files_but_refuses_existing_example_files
    Dir.mktmpdir("three-rb-browser-generator") do |dir|
      FileUtils.mkdir_p(File.join(dir, "lib"))
      File.write(File.join(dir, "lib/three.rb"), "# existing\n")

      generator = Three::Generators::BrowserExample.new(
        target: "examples/browser/quickstart",
        root: dir,
        stream: StringIO.new
      ).call

      assert_includes generator.skipped, "lib/three.rb"

      assert_raises(ArgumentError) do
        Three::Generators::BrowserExample.new(
          target: "examples/browser/quickstart",
          root: dir,
          stream: StringIO.new
        ).call
      end
    end
  end

  def test_refuses_existing_example_files_before_copying_runtime
    Dir.mktmpdir("three-rb-browser-generator") do |dir|
      target = File.join(dir, "examples/browser/quickstart")
      FileUtils.mkdir_p(target)
      File.write(File.join(target, "main.rb"), "# existing\n")

      assert_raises(ArgumentError) do
        Three::Generators::BrowserExample.new(
          target: "examples/browser/quickstart",
          root: dir,
          stream: StringIO.new
        ).call
      end

      refute_path_exists File.join(dir, "package.json")
      refute_path_exists File.join(dir, "lib/three.rb")
    end
  end

  def test_refuses_target_outside_project_root
    Dir.mktmpdir("three-rb-browser-generator") do |dir|
      error = assert_raises(ArgumentError) do
        Three::Generators::BrowserExample.new(
          target: File.join(dir, "..", "quickstart"),
          root: dir,
          stream: StringIO.new
        ).call
      end

      assert_match(/target must be inside/, error.message)
    end
  end

  def test_refuses_project_root_as_target
    Dir.mktmpdir("three-rb-browser-generator") do |dir|
      error = assert_raises(ArgumentError) do
        Three::Generators::BrowserExample.new(
          target: ".",
          root: dir,
          stream: StringIO.new
        ).call
      end

      assert_match(/not the project root/, error.message)
    end
  end

  def test_force_overwrites_generated_example_files
    Dir.mktmpdir("three-rb-browser-generator") do |dir|
      target = File.join(dir, "examples/browser/quickstart")
      FileUtils.mkdir_p(target)
      File.write(File.join(target, "main.rb"), "# stale\n")

      Three::Generators::BrowserExample.new(
        target: "examples/browser/quickstart",
        root: dir,
        force: true,
        stream: StringIO.new
      ).call

      main = File.read(File.join(target, "main.rb"))
      assert_includes main, "Three::Browser.run"
      refute_includes main, "# stale"
    end
  end
end
