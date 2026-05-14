# frozen_string_literal: true

require "json"
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
assert(exported.fetch(:metadata).fetch(:generator) == "three.rb", "expected three.rb export metadata")
assert(loaded.is_a?(Three::Scene), "expected JSON loader to reconstruct a scene")
assert(loaded.children.any? { |child| child.is_a?(Three::PerspectiveCamera) }, "expected camera to round-trip")
assert(loaded.children.any? { |child| child.is_a?(Three::Mesh) }, "expected mesh to round-trip")
assert(defined?(Three::Renderers::ThreeJSRenderer), "expected browser renderer API to load")
assert(defined?(Three::Controls::OrbitControls), "expected controls API to load")
assert(defined?(Three::MeshMatcapMaterial), "expected matcap material API to load")
assert(defined?(Three::Postprocessing::EffectComposer), "expected postprocessing API to load")
assert(defined?(Three::Postprocessing::OutputPass), "expected output pass API to load")

puts "gem install smoke passed for three.rb #{Three::VERSION}"
