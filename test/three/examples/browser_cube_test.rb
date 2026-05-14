# frozen_string_literal: true

require "test_helper"
require "json"

class ThreeBrowserCubeExampleTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  EXAMPLE_DIR = File.join(ROOT, "examples/browser/cube")
  COMPOSITION_EXAMPLE_DIR = File.join(ROOT, "examples/browser/composition")
  TEXTURES_EXAMPLE_DIR = File.join(ROOT, "examples/browser/textures")
  CUBEMAP_EXAMPLE_DIR = File.join(ROOT, "examples/browser/cubemap")
  GLTF_EXAMPLE_DIR = File.join(ROOT, "examples/browser/gltf")
  SERIALIZATION_EXAMPLE_DIR = File.join(ROOT, "examples/browser/serialization")
  PICKING_EXAMPLE_DIR = File.join(ROOT, "examples/browser/picking")
  PRIMITIVES_EXAMPLE_DIR = File.join(ROOT, "examples/browser/primitives")
  POSTPROCESSING_EXAMPLE_DIR = File.join(ROOT, "examples/browser/postprocessing")
  OVERVIEW_PATH = File.join(ROOT, "examples/browser/README.md")
  BROWSER_EXAMPLES = {
    "cube" => "test:browser:cube",
    "composition" => "test:browser:composition",
    "textures" => "test:browser:textures",
    "cubemap" => "test:browser:cubemap",
    "gltf" => "test:browser:gltf",
    "serialization" => "test:browser:serialization",
    "picking" => "test:browser:picking",
    "primitives" => "test:browser:primitives",
    "postprocessing" => "test:browser:postprocessing"
  }.freeze

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

  def test_browser_textures_example_files_exist
    assert_path_exists File.join(TEXTURES_EXAMPLE_DIR, "index.html")
    assert_path_exists File.join(TEXTURES_EXAMPLE_DIR, "main.rb")
    assert_path_exists File.join(TEXTURES_EXAMPLE_DIR, "README.md")
    assert_path_exists File.join(TEXTURES_EXAMPLE_DIR, "smoke_test.mjs")
  end

  def test_browser_cubemap_example_files_exist
    assert_path_exists File.join(CUBEMAP_EXAMPLE_DIR, "index.html")
    assert_path_exists File.join(CUBEMAP_EXAMPLE_DIR, "main.rb")
    assert_path_exists File.join(CUBEMAP_EXAMPLE_DIR, "README.md")
    assert_path_exists File.join(CUBEMAP_EXAMPLE_DIR, "smoke_test.mjs")
  end

  def test_browser_gltf_example_files_exist
    assert_path_exists File.join(GLTF_EXAMPLE_DIR, "index.html")
    assert_path_exists File.join(GLTF_EXAMPLE_DIR, "main.rb")
    assert_path_exists File.join(GLTF_EXAMPLE_DIR, "README.md")
    assert_path_exists File.join(GLTF_EXAMPLE_DIR, "smoke_test.mjs")
    assert_path_exists File.join(ROOT, "examples/browser/assets/triangle.gltf")
    assert_path_exists File.join(ROOT, "examples/browser/assets/animated_triangle.gltf")
    assert_path_exists File.join(ROOT, "examples/browser/assets/compressed_triangle.gltf")
  end

  def test_browser_serialization_example_files_exist
    assert_path_exists File.join(SERIALIZATION_EXAMPLE_DIR, "index.html")
    assert_path_exists File.join(SERIALIZATION_EXAMPLE_DIR, "main.rb")
    assert_path_exists File.join(SERIALIZATION_EXAMPLE_DIR, "README.md")
    assert_path_exists File.join(SERIALIZATION_EXAMPLE_DIR, "smoke_test.mjs")
  end

  def test_browser_picking_example_files_exist
    assert_path_exists File.join(PICKING_EXAMPLE_DIR, "index.html")
    assert_path_exists File.join(PICKING_EXAMPLE_DIR, "main.rb")
    assert_path_exists File.join(PICKING_EXAMPLE_DIR, "README.md")
    assert_path_exists File.join(PICKING_EXAMPLE_DIR, "smoke_test.mjs")
  end

  def test_browser_primitives_example_files_exist
    assert_path_exists File.join(PRIMITIVES_EXAMPLE_DIR, "index.html")
    assert_path_exists File.join(PRIMITIVES_EXAMPLE_DIR, "main.rb")
    assert_path_exists File.join(PRIMITIVES_EXAMPLE_DIR, "README.md")
    assert_path_exists File.join(PRIMITIVES_EXAMPLE_DIR, "smoke_test.mjs")
  end

  def test_browser_postprocessing_example_files_exist
    assert_path_exists File.join(POSTPROCESSING_EXAMPLE_DIR, "index.html")
    assert_path_exists File.join(POSTPROCESSING_EXAMPLE_DIR, "main.rb")
    assert_path_exists File.join(POSTPROCESSING_EXAMPLE_DIR, "README.md")
    assert_path_exists File.join(POSTPROCESSING_EXAMPLE_DIR, "smoke_test.mjs")
  end

  def test_browser_examples_overview_documents_smoke_coverage
    overview = File.read(OVERVIEW_PATH)
    package = JSON.parse(File.read(File.join(ROOT, "package.json")))

    assert_includes overview, "# Browser Examples"
    assert_includes overview, "pnpm test:browser"
    assert_includes overview, "New browser-facing features should add or extend one of these examples"

    BROWSER_EXAMPLES.each do |example, script|
      assert_includes overview, "examples/browser/#{example}/"
      assert_includes overview, "pnpm #{script}"
      assert_equal "node examples/browser/#{example}/smoke_test.mjs", package.fetch("scripts").fetch(script)
    end
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
    assert_includes ruby, "Three::MeshPhongMaterial"
    assert_includes ruby, "Three::MeshStandardMaterial"
    assert_includes ruby, "Three::ShadowMaterial"
    assert_includes ruby, "Three::InstancedMesh"
    assert_includes ruby, "Three::Loaders::TextureLoader"
    assert_includes ruby, "Three::RepeatWrapping"
    assert_includes ruby, "Three::NearestFilter"
    assert_includes ruby, "Three::PointLight"
    assert_includes ruby, "Three::HemisphereLight"
    assert_includes ruby, "Three::Controls::OrbitControls"
    assert_includes ruby, "Three::Group"
    assert_includes ruby, "shadow_map_enabled: true"
    assert_includes ruby, "cast_shadow = true"
    assert_includes ruby, "receive_shadow = true"
    assert_includes ruby, "rig.add(primary)"
    assert_includes ruby, "rig.add(satellite)"
    assert_includes ruby, "instanced_field.set_matrix_at"
    assert_includes ruby, "instanced_field.set_color_at"
    assert_includes ruby, "primary_material.color.set_rgb"
    assert_includes ruby, "JS.global[:__threeRbShadowMaterial]"
    assert_includes ruby, "renderer.animation_loop"
  end

  def test_textures_example_exercises_texture_settings
    ruby = File.read(File.join(TEXTURES_EXAMPLE_DIR, "main.rb"))

    assert_includes ruby, "Three::Loaders::TextureLoader"
    assert_includes ruby, "Three::Loaders::RGBELoader"
    assert_includes ruby, "scene.environment = environment_texture"
    assert_includes ruby, "Three::RepeatWrapping"
    assert_includes ruby, "Three::NearestFilter"
    assert_includes ruby, "texture.offset.set(0.125, 0.25)"
    assert_includes ruby, "texture.repeat.set(4, 3)"
    assert_includes ruby, "texture.center.set(0.5, 0.5)"
    assert_includes ruby, "texture.rotation = 0.35"
    assert_includes ruby, "Three::MeshPhysicalMaterial"
    assert_includes ruby, "map: texture"
    assert_includes ruby, "anisotropy_map: texture"
    assert_includes ruby, "clearcoat_map: texture"
    assert_includes ruby, "specular_intensity:"
    assert_includes ruby, "Three::MeshMatcapMaterial"
    assert_includes ruby, "matcap: texture"
    assert_includes ruby, "Three::MeshToonMaterial"
    assert_includes ruby, "gradient_map: texture"
    assert_includes ruby, "JS.global[:__threeRbMatcapMaterial]"
    assert_includes ruby, "JS.global[:__threeRbToonMaterial]"
    assert_includes ruby, "renderer.animation_loop"
  end

  def test_cubemap_example_exercises_cube_texture_loader
    ruby = File.read(File.join(CUBEMAP_EXAMPLE_DIR, "main.rb"))

    assert_includes ruby, "Three::Loaders::CubeTextureLoader"
    assert_includes ruby, "scene.background = cube_texture"
    assert_includes ruby, "scene.environment = cube_texture"
    assert_includes ruby, "Three::SphereGeometry"
    assert_includes ruby, "Three::MeshStandardMaterial"
    assert_includes ruby, "renderer.animation_loop"
  end

  def test_gltf_example_exercises_gltf_loader
    ruby = File.read(File.join(GLTF_EXAMPLE_DIR, "main.rb"))

    assert_includes ruby, "Three::Loaders::GLTFLoader"
    assert_includes ruby, "draco_decoder_path:"
    assert_includes ruby, "compressed_triangle.gltf"
    assert_includes ruby, "Three::AnimationMixer"
    assert_includes ruby, "Three::Clock"
    assert_includes ruby, "mixer.update"
    assert_includes ruby, "scene.add(model)"
    assert_includes ruby, "renderer.backend.materialize(model)"
    assert_includes ruby, "renderer.animation_loop"
  end

  def test_serialization_example_exercises_json_export_and_load
    ruby = File.read(File.join(SERIALIZATION_EXAMPLE_DIR, "main.rb"))

    assert_includes ruby, "Three::Exporters::ThreeJSONExporter"
    assert_includes ruby, "Three::Loaders::ThreeJSONLoader"
    assert_includes ruby, "deterministic_ids: true"
    assert_includes ruby, "left.geometry.equal?(right.geometry)"
    assert_includes ruby, "renderer.render(scene, camera)"
  end

  def test_picking_example_exercises_raycaster
    ruby = File.read(File.join(PICKING_EXAMPLE_DIR, "main.rb"))

    assert_includes ruby, "Three::Raycaster"
    assert_includes ruby, "raycaster.set_from_camera"
    assert_includes ruby, "raycaster.intersect_objects"
    assert_includes ruby, "selected.material.color.set_hex"
    assert_includes ruby, "addEventListener, \"click\""
  end

  def test_primitives_example_exercises_line_and_points
    ruby = File.read(File.join(PRIMITIVES_EXAMPLE_DIR, "main.rb"))

    assert_includes ruby, "Three::Line"
    assert_includes ruby, "Three::Points"
    assert_includes ruby, "Three::LineBasicMaterial"
    assert_includes ruby, "Three::PointsMaterial"
    assert_includes ruby, "Three::Float32BufferAttribute"
  end

  def test_postprocessing_example_exercises_composer_and_bloom_pipeline
    ruby = File.read(File.join(POSTPROCESSING_EXAMPLE_DIR, "main.rb"))

    assert_includes ruby, "Three::Postprocessing::EffectComposer"
    assert_includes ruby, "Three::Postprocessing::RenderPass"
    assert_includes ruby, "Three::Postprocessing::UnrealBloomPass"
    assert_includes ruby, "Three::Postprocessing::DotScreenPass"
    assert_includes ruby, "Three::Postprocessing::OutputPass"
    assert_includes ruby, "composer.add_pass(render_pass)"
    assert_includes ruby, "composer.add_pass(bloom_pass)"
    assert_includes ruby, "composer.add_pass(dot_screen_pass)"
    assert_includes ruby, "composer.add_pass(output_pass)"
    assert_includes ruby, "composer.set_size(width, height)"
    assert_includes ruby, "composer.render(scene, camera)"
    assert_includes ruby, "bloom_pass.strength ="
    assert_includes ruby, "dot_screen_pass.scale ="
    assert_includes ruby, "preserveDrawingBuffer: true"
  end

  def test_package_script_runs_browser_smoke_test
    package = JSON.parse(File.read(File.join(ROOT, "package.json")))

    assert_match(/\Apnpm@/, package.fetch("packageManager"))
    assert_equal "0.4.2", package.fetch("dependencies").fetch("@bjorn3/browser_wasi_shim")
    assert_equal "2.9.4-2026-05-11-a", package.fetch("dependencies").fetch("@ruby/3.4-wasm-wasi")
    assert_equal "2.9.4-2026-05-11-a", package.fetch("dependencies").fetch("@ruby/wasm-wasi")
    assert_equal "0.184.0", package.fetch("dependencies").fetch("three")
    assert_equal "pnpm test:browser:cube && pnpm test:browser:composition && pnpm test:browser:textures && pnpm test:browser:cubemap && pnpm test:browser:gltf && pnpm test:browser:serialization && pnpm test:browser:picking && pnpm test:browser:primitives && pnpm test:browser:postprocessing", package.fetch("scripts").fetch("test:browser")
    assert_equal "node examples/browser/cube/smoke_test.mjs", package.fetch("scripts").fetch("test:browser:cube")
    assert_equal "node examples/browser/composition/smoke_test.mjs", package.fetch("scripts").fetch("test:browser:composition")
    assert_equal "node examples/browser/textures/smoke_test.mjs", package.fetch("scripts").fetch("test:browser:textures")
    assert_equal "node examples/browser/cubemap/smoke_test.mjs", package.fetch("scripts").fetch("test:browser:cubemap")
    assert_equal "node examples/browser/gltf/smoke_test.mjs", package.fetch("scripts").fetch("test:browser:gltf")
    assert_equal "node examples/browser/serialization/smoke_test.mjs", package.fetch("scripts").fetch("test:browser:serialization")
    assert_equal "node examples/browser/picking/smoke_test.mjs", package.fetch("scripts").fetch("test:browser:picking")
    assert_equal "node examples/browser/primitives/smoke_test.mjs", package.fetch("scripts").fetch("test:browser:primitives")
    assert_equal "node examples/browser/postprocessing/smoke_test.mjs", package.fetch("scripts").fetch("test:browser:postprocessing")
    assert_includes package.fetch("devDependencies"), "playwright"
  end
end
