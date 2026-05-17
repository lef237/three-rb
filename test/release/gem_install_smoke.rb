# frozen_string_literal: true

require "json"
require "open3"
require "tmpdir"
require "three"

def assert(condition, message)
  raise message unless condition
end

scene = Three::Scene.new
camera = Three::PerspectiveCamera.new(55, aspect: 16.0 / 9.0, near: 0.1, far: 100)
camera.position.z = 4
scene.add(camera)

texture = Three::Texture.new("/checker.svg", wrap_s: Three::RepeatWrapping, wrap_t: Three::RepeatWrapping)
material = Three::MeshPhysicalMaterial.new(
  color: 0x77a8ff,
  roughness: 0.42,
  metalness: 0.08,
  clearcoat: 0.5,
  map: texture
)
mesh = Three::Mesh.new(Three::BoxGeometry.new(1, 1, 1), material)
mesh.position.set(1, 2, 3)
scene.add(mesh)

exporter = Three::Exporters::ThreeJSONExporter.new(deterministic_ids: true)
exported = exporter.export(scene)
json = JSON.generate(exported)
loaded = Three::Loaders::ThreeJSONLoader.new.parse(json)

assert(Three::VERSION.match?(/\A\d+\.\d+\.\d+\z/), "expected a semantic gem version")
assert(exported.fetch(:metadata).fetch(:generator) == "three-rb", "expected three-rb export metadata")
assert(loaded.is_a?(Three::Scene), "expected JSON loader to reconstruct a scene")
assert(loaded.children.any? { |child| child.is_a?(Three::PerspectiveCamera) }, "expected camera to round-trip")
assert(loaded.children.any? { |child| child.is_a?(Three::Mesh) }, "expected mesh to round-trip")
assert(defined?(Three::Renderers::ThreeJSRenderer), "expected browser renderer API to load")
assert(defined?(Three::Controls::OrbitControls), "expected controls API to load")
assert(defined?(Three::MeshMatcapMaterial), "expected matcap material API to load")
assert(defined?(Three::MeshToonMaterial), "expected toon material API to load")
assert(defined?(Three::ShadowMaterial), "expected shadow material API to load")
assert(defined?(Three::Sprite), "expected sprite object API to load")
assert(defined?(Three::SpriteMaterial), "expected sprite material API to load")
assert(defined?(Three::Postprocessing::EffectComposer), "expected postprocessing API to load")
assert(defined?(Three::Postprocessing::OutputPass), "expected output pass API to load")
assert(defined?(Three::Postprocessing::DotScreenPass), "expected dot screen pass API to load")

spec = Gem::Specification.find_by_name("three-rb")
executable = File.join(Gem.bindir, "three-rb")

assert(spec.executables.include?("three-rb"), "expected three-rb executable in gemspec")
assert(File.executable?(executable), "expected installed three-rb executable")

Dir.mktmpdir("three-rb-installed-cli") do |dir|
  stdout, stderr, status = Open3.capture3(executable, "browser", "examples/browser/quickstart", chdir: dir)
  assert(status.success?, "expected three-rb browser to succeed: #{stderr}")
  assert(stdout.include?("Created browser example"), "expected generator output")

  main = File.read(File.join(dir, "examples/browser/quickstart/main.rb"))
  boot = File.read(File.join(dir, "examples/browser/quickstart/boot.mjs"))

  assert(File.file?(File.join(dir, "package.json")), "expected package.json to be generated")
  assert(File.file?(File.join(dir, "examples/browser/shared/boot.mjs")), "expected shared browser boot to be generated")
  assert(main.include?("Three::Browser.run"), "expected generated Ruby to use Three::Browser.run")
  assert(!main.include?("require \"js\""), "expected generated Ruby to avoid require js")
  assert(!main.include?("JS.global"), "expected generated Ruby to avoid JS.global")
  assert(boot.include?("examples/browser/quickstart/main"), "expected boot file to load generated Ruby entrypoint")
end

puts "gem install smoke passed for three-rb #{Three::VERSION}"
