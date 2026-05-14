# frozen_string_literal: true

require "test_helper"
require "json"

class ThreeJSONFixtureTest < Minitest::Test
  ROOT = File.expand_path("../../..", __dir__)
  FIXTURE_PATH = File.join(ROOT, "test/fixtures/scene_export_v1.json")

  def test_export_matches_saved_fixture
    assert_equal File.read(FIXTURE_PATH), SceneFixtureBuilder.serialization_fixture_json
  end

  def test_saved_fixture_loads_expected_scene_graph
    loaded = Three::Loaders::ThreeJSONLoader.new.parse(File.read(FIXTURE_PATH))

    assert_instance_of Three::Scene, loaded
    assert_equal "fixture-scene", loaded.name
    assert_equal({ "purpose" => "json-regression", "version" => 1 }, loaded.user_data)
    assert_instance_of Three::RGBETexture, loaded.environment
    assert_equal "/fixtures/studio.hdr", loaded.environment.source

    assert_child_types loaded, [Three::PerspectiveCamera, Three::AmbientLight, Three::DirectionalLight, Three::Group, Three::InstancedMesh]

    camera = find_child(loaded, "main-camera")
    assert_instance_of Three::PerspectiveCamera, camera
    assert_equal 55, camera.fov
    assert_equal 16.0 / 9.0, camera.aspect
    assert_equal 1.1, camera.zoom
    assert_vector3_in_delta [0, 1.4, 6], camera.position

    key_light = find_child(loaded, "key-light")
    assert_instance_of Three::DirectionalLight, key_light
    assert key_light.cast_shadow
    assert_equal [1024, 1024], key_light.shadow_map_size
    assert_equal(-4, key_light.shadow_camera[:left])
    assert_equal 4, key_light.shadow_camera[:right]

    rig = find_child(loaded, "fixture-rig")
    assert_instance_of Three::Group, rig
    assert_child_types rig, [Three::Mesh, Three::Line, Three::Points]
  end

  def test_saved_fixture_preserves_material_texture_slots_and_shared_resources
    loaded = Three::Loaders::ThreeJSONLoader.new.parse(File.read(FIXTURE_PATH))
    rig = find_child(loaded, "fixture-rig")
    cube = find_child(rig, "physical-cube")
    line = find_child(rig, "fixture-line")
    points = find_child(rig, "fixture-points")

    material = cube.material
    assert_instance_of Three::MeshPhysicalMaterial, material
    assert_equal 0x99ccff, material.color.hex
    assert_equal 0.38, material.roughness
    assert_equal 0.12, material.metalness
    assert_equal 0.25, material.anisotropy
    assert_equal 0.15, material.anisotropy_rotation
    assert_equal 0.7, material.clearcoat
    assert_equal 0.2, material.clearcoat_roughness
    assert_equal 0.75, material.specular_intensity
    assert_equal 0xf0f6ff, material.specular_color.hex

    assert_same material.map, material.roughness_map
    assert_same material.map, points.material.map
    assert_same material.map, find_child(loaded, "fixture-instanced").material.map
    assert_equal "/fixtures/checker.png", material.map.source
    assert_equal "/fixtures/clearcoat.png", material.clearcoat_map.source
    assert_equal "/fixtures/specular.png", material.specular_color_map.source
    assert_equal [0.125, 0.25], material.map.offset.to_a
    assert_equal [3, 2], material.map.repeat.to_a
    assert_equal 0.35, material.map.rotation

    assert_same line.geometry, points.geometry
    assert_equal "shared-primitive-geometry", line.geometry.name
    assert_equal 4, line.geometry.get_attribute(:position).count
  end

  def test_saved_fixture_preserves_instanced_mesh_data
    loaded = Three::Loaders::ThreeJSONLoader.new.parse(File.read(FIXTURE_PATH))
    instanced = find_child(loaded, "fixture-instanced")

    assert_instance_of Three::InstancedMesh, instanced
    assert_equal 2, instanced.count
    assert_equal 3, instanced.capacity
    assert_instance_of Three::PlaneGeometry, instanced.geometry
    assert_equal Three::Matrix4.new.make_translation(-1.0, -0.8, 0.2), instanced.get_matrix_at(0)
    assert_equal Three::Matrix4.new.make_translation(0.0, -0.8, 0.2), instanced.get_matrix_at(1)
    assert_equal Three::Matrix4.new.make_translation(1.0, -0.8, 0.2), instanced.get_matrix_at(2)
    assert_equal Three::Color.new(0.25, 0.55, 0.9), instanced.get_color_at(0)
    assert_equal Three::Color.new(0.9, 0.7, 0.25), instanced.get_color_at(1)
    assert_equal Three::Color.new(0.45, 0.9, 0.55), instanced.get_color_at(2)
  end

  private

  def find_child(parent, name)
    parent.children.find { |child| child.name == name } || flunk("expected child named #{name.inspect}")
  end

  def assert_child_types(parent, expected_types)
    assert_equal expected_types, parent.children.map(&:class)
  end
end
