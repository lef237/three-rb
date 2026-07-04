# frozen_string_literal: true

require "fileutils"
require "cgi"
require "json"
require "pathname"

module Three
  module Generators
    class BrowserExample
      attr_reader :created, :skipped

      def initialize(target:, root: Dir.pwd, force: false, stream: $stdout)
        @root = File.expand_path(root)
        @target = File.expand_path(target, @root)
        @force = force
        @stream = stream
        @created = []
        @skipped = []
      end

      def call
        validate_target!
        validate_example_files!
        copy_runtime
        write_example_files
        report
        self
      end

      private

      def validate_target!
        target_path = Pathname.new(@target)
        root_path = Pathname.new(@root)
        relative = begin
          target_path.relative_path_from(root_path).to_s
        rescue ArgumentError
          raise ArgumentError, "target must be inside #{root_path}"
        end

        raise ArgumentError, "target must be a directory inside #{root_path}, not the project root" if relative == "."
        return unless relative == ".." || relative.start_with?("../")

        raise ArgumentError, "target must be inside #{root_path}"
      end

      def validate_example_files!
        return if @force

        example_files.each do |path|
          next unless File.exist?(path)

          raise ArgumentError, "#{relative_path(path)} already exists; pass --force to overwrite generated example files"
        end
      end

      def copy_runtime
        copy_file(runtime_path("package.json"), File.join(@root, "package.json"), overwrite: false)
        copy_file(runtime_path("pnpm-lock.yaml"), File.join(@root, "pnpm-lock.yaml"), overwrite: false)
        copy_tree(runtime_path("lib"), File.join(@root, "lib"), overwrite: false)
        copy_file(
          runtime_path("examples/browser/shared/boot.mjs"),
          File.join(File.dirname(@target), "shared", "boot.mjs"),
          overwrite: @force
        )
      end

      def write_example_files
        if ruby_example?
          copy_ruby_example_files
        else
          write_file(example_path("index.html"), index_html, overwrite: @force)
          write_file(example_path("boot.mjs"), boot_js, overwrite: @force)
          write_file(example_path("main.rb"), main_rb, overwrite: @force)
          write_file(example_path("README.md"), readme, overwrite: @force)
        end
      end

      def copy_ruby_example_files
        {
          "index.html" => "index.html",
          "boot.mjs" => "boot.mjs",
          "main.rb" => "main.rb",
          "assets/studio.hdr" => "assets/studio.hdr"
        }.each do |source_name, destination_name|
          copy_generated_file(
            runtime_path(File.join("examples/browser/ruby", source_name)),
            example_path(destination_name),
            overwrite: @force
          )
        end

        write_ruby_readme
      end

      def write_ruby_readme
        source = runtime_path("examples/browser/ruby/README.md")
        destination = example_path("README.md")
        if File.exist?(destination) && File.identical?(source, destination)
          @skipped << relative_path(destination)
          return
        end

        write_file(destination, ruby_readme, overwrite: @force)
      end

      def copy_tree(source, destination, overwrite:)
        Dir.glob(File.join(source, "**/*"), File::FNM_DOTMATCH).each do |path|
          next if File.directory?(path)

          relative = Pathname.new(path).relative_path_from(Pathname.new(source)).to_s
          copy_file(path, File.join(destination, relative), overwrite: overwrite)
        end
      end

      def copy_file(source, destination, overwrite:)
        if File.exist?(destination) && File.identical?(source, destination)
          @skipped << relative_path(destination)
          return
        end

        if File.exist?(destination) && !overwrite
          @skipped << relative_path(destination)
          return
        end

        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(source, destination)
        @created << relative_path(destination)
      end

      def copy_generated_file(source, destination, overwrite:)
        if File.exist?(destination) && File.identical?(source, destination)
          @skipped << relative_path(destination)
          return
        end

        if File.exist?(destination) && !overwrite
          raise ArgumentError, "#{relative_path(destination)} already exists; pass --force to overwrite generated example files"
        end

        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.cp(source, destination)
        @created << relative_path(destination)
      end

      def write_file(path, content, overwrite:)
        if File.exist?(path) && !overwrite
          raise ArgumentError, "#{relative_path(path)} already exists; pass --force to overwrite generated example files"
        end

        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
        @created << relative_path(path)
      end

      def report
        @stream.puts "Created browser example at #{relative_path(@target)}"
        @stream.puts "Created #{created.length} files" unless created.empty?
        @stream.puts "Skipped #{skipped.length} existing runtime files" unless skipped.empty?
      end

      def runtime_path(relative)
        File.expand_path(File.join("../../../", relative), __dir__)
      end

      def example_files
        names = %w[index.html boot.mjs main.rb README.md]
        names << "assets/studio.hdr" if ruby_example?
        names.map { |name| example_path(name) }
      end

      def example_path(name)
        File.join(@target, name)
      end

      def relative_path(path)
        Pathname.new(path).relative_path_from(Pathname.new(@root)).to_s
      end

      def main_module_path
        File.join(relative_path(@target), "main").delete_prefix("./")
      end

      def require_three_path
        Pathname
          .new(File.join(@root, "lib", "three"))
          .relative_path_from(Pathname.new(@target))
          .to_s
      end

      def shared_boot_path
        Pathname
          .new(File.join(File.dirname(@target), "shared", "boot.mjs"))
          .relative_path_from(Pathname.new(@target))
          .to_s
      end

      def title
        "three-rb #{File.basename(@target)}"
      end

      def html_text(text)
        CGI.escapeHTML(text)
      end

      def js_string(text)
        JSON.generate(text)
      end

      def ruby_example?
        relative_path(@target) == "examples/browser/ruby"
      end

      def index_html
        <<~HTML
          <!doctype html>
          <html lang="en">
            <head>
              <meta charset="utf-8">
              <meta name="viewport" content="width=device-width, initial-scale=1">
              <title>#{html_text(title)}</title>
              <style>
                :root {
                  color-scheme: dark;
                  font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
                  background: #101418;
                  color: #eef3f7;
                }

                * { box-sizing: border-box; }
                html, body, #viewport { width: 100%; height: 100%; margin: 0; }
                body { overflow: hidden; }
                #viewport { position: relative; min-width: 320px; min-height: 320px; }
                canvas { display: block; width: 100%; height: 100%; }
                .hud {
                  position: absolute;
                  top: 16px;
                  left: 16px;
                  display: grid;
                  grid-template-columns: auto minmax(0, 1fr);
                  align-items: center;
                  gap: 8px;
                  min-width: min(360px, calc(100% - 32px));
                  padding: 8px 10px;
                  border: 1px solid rgba(255, 255, 255, 0.14);
                  border-radius: 6px;
                  background: rgba(10, 14, 18, 0.72);
                  color: #dce7ef;
                  font-size: 13px;
                  backdrop-filter: blur(10px);
                }
                .status-dot {
                  width: 8px;
                  height: 8px;
                  border-radius: 999px;
                  background: #f2b84b;
                }
                .status-dot[data-state="running"] { background: #4ed08f; }
                .status-dot[data-state="error"] { background: #f15b5b; }
                .status-dot[data-state="loading"] { animation: status-dot-pulse 1.2s ease-in-out infinite; }
                @keyframes status-dot-pulse {
                  0%, 100% { opacity: 1; transform: scale(1); }
                  50% { opacity: 0.4; transform: scale(0.75); }
                }
                .progress {
                  grid-column: 1 / -1;
                  width: 100%;
                  height: 4px;
                  overflow: hidden;
                  border-radius: 999px;
                  background: rgba(255, 255, 255, 0.16);
                }
                .progress-bar {
                  width: 4%;
                  height: 100%;
                  border-radius: inherit;
                  background: linear-gradient(90deg, #55ace0, #4ed08f);
                  transition: width 180ms ease;
                }
                .progress[hidden] { display: none; }
              </style>
              <script type="importmap">
                {
                  "imports": {
                    "@bjorn3/browser_wasi_shim": "/node_modules/@bjorn3/browser_wasi_shim/dist/index.js",
                    "@ruby/wasm-wasi/browser": "/node_modules/@ruby/wasm-wasi/dist/esm/browser.js",
                    "three": "/node_modules/three/build/three.module.js",
                    "three/addons/": "/node_modules/three/examples/jsm/"
                  }
                }
              </script>
              <script type="module">
                const status = document.querySelector("#status");
                const statusDot = document.querySelector("#status-dot");
                const progress = document.querySelector("#progress");
                const progressBar = document.querySelector("#progress-bar");

                globalThis.__threeRbSetStatus = (message, state, percent) => {
                  if (status) status.textContent = message;
                  if (statusDot) statusDot.dataset.state = state;
                  if (progress && progressBar) {
                    if (state === "running" || state === "error") {
                      progress.hidden = true;
                    } else {
                      progress.hidden = false;
                      if (Number.isFinite(percent)) {
                        progressBar.style.width = `${Math.max(4, Math.min(100, percent))}%`;
                      }
                    }
                  }
                };
                globalThis.__threeRbBootFailed = (message) => globalThis.__threeRbSetStatus(message, "error");
                globalThis.addEventListener("error", (event) => globalThis.__threeRbBootFailed(event.message || "Browser error"));
                globalThis.addEventListener("unhandledrejection", (event) => {
                  const reason = event.reason;
                  globalThis.__threeRbBootFailed(reason && reason.message ? reason.message : "Ruby boot failed");
                });
                globalThis.setTimeout(() => {
                  if (status && statusDot && statusDot.dataset.state === "loading") {
                    status.textContent = "Still loading after 30 seconds. Try reloading the page.";
                  }
                }, 30000);
                globalThis.__threeRbSetStatus("Loading ruby.wasm", "loading", 4);
              </script>
              <script type="module" src="./boot.mjs"></script>
            </head>
            <body>
              <main id="viewport">
                <canvas id="scene" data-testid="scene-canvas"></canvas>
                <div class="hud" aria-live="polite">
                  <span class="status-dot" id="status-dot" data-state="loading"></span>
                  <span id="status" data-testid="status">Loading ruby.wasm</span>
                  <div class="progress" id="progress" aria-hidden="true">
                    <div class="progress-bar" id="progress-bar"></div>
                  </div>
                </div>
              </main>
            </body>
          </html>
        HTML
      end

      def boot_js
        <<~JS
          import { bootRubyExample } from #{js_string(shared_boot_path)};

          await bootRubyExample({
            main: #{js_string(main_module_path)},
            clearColor: 0x101418
          });
        JS
      end

      def main_rb
        <<~RUBY
          # frozen_string_literal: true

          require_relative "#{require_three_path}"

          Three::Browser.run(starting: "Starting Ruby scene") do |app|
            scene = Three::Scene.new
            camera = Three::PerspectiveCamera.new(70, aspect: 1.0, near: 0.1, far: 100)
            camera.position.z = 3

            cube = Three::Mesh.new(
              Three::BoxGeometry.new(1, 1, 1),
              Three::MeshBasicMaterial.new(color: 0x4ed08f)
            )
            scene.add(cube)

            renderer = Three::Renderers::ThreeJSRenderer.new(
              canvas: "#scene",
              antialias: true,
              alpha: false
            )
            renderer.set_clear_color(0x101418, 1)

            app.resize_renderer(renderer, camera)
            renderer.render(scene, camera)

            app.animation_loop(renderer) do
              cube.rotation.x += 0.01
              cube.rotation.y += 0.015
              renderer.render(scene, camera)
            end
          end
        RUBY
      end

      def readme
        <<~MARKDOWN
          # #{title}

          This generated browser example runs Ruby through ruby.wasm and renders with three.js.

          From the project root:

          ```sh
          pnpm install
          ruby -run -e httpd . -p 8000
          ```

          Open:

          ```text
          http://localhost:8000/#{relative_path(@target)}/
          ```

          Keep serving the project root. The browser runtime loads `node_modules/`, `lib/`, and this example over HTTP.
        MARKDOWN
      end

      def ruby_readme
        <<~MARKDOWN
          # three-rb Ruby Example

          This generated browser example runs Ruby through ruby.wasm and renders a faceted red gemstone with a three-dimensional `three-rb` title.

          From the project root:

          ```sh
          pnpm install
          ruby -run -e httpd . -p 8000
          ```

          Open:

          ```text
          http://localhost:8000/#{relative_path(@target)}/
          ```

          Keep serving the project root. The browser runtime loads `node_modules/`, `lib/`, and this example's local `assets/` directory over HTTP.
        MARKDOWN
      end
    end
  end
end
