# frozen_string_literal: true

require "test_helper"

class ThreeThreeJSONLoaderTest < Minitest::Test
  def test_parse_reconstructs_exported_scene_with_shared_resources
    scene = Three::Scene.new
    texture = Three::Texture.new("/texture.png", offset: [0.25, 0.5], repeat: [2, 3], center: [0.5, 0.5], rotation: 0.35)
    geometry = Three::BoxGeometry.new(1, 2, 3)
    material = Three::MeshBasicMaterial.new(color: 0x00ff00, map: texture)
    first = Three::Mesh.new(geometry, material)
    second = Three::Mesh.new(geometry, material)
    first.position.set(1, 2, 3)
    second.scale.set(2, 2, 2)
    second.layers.set(2)
    scene.add(first, second)

    loaded = Three::Loaders::ThreeJSONLoader.new.parse(scene.to_json)

    assert_instance_of Three::Scene, loaded
    assert_equal 2, loaded.children.length
    assert_instance_of Three::Mesh, loaded.children[0]
    assert_instance_of Three::BoxGeometry, loaded.children[0].geometry
    assert_equal({ width: 1, height: 2, depth: 3, width_segments: 1, height_segments: 1, depth_segments: 1 }, loaded.children[0].geometry.parameters)
    assert_instance_of Three::MeshBasicMaterial, loaded.children[0].material
    assert_equal 0x00ff00, loaded.children[0].material.color.hex
    assert_equal "/texture.png", loaded.children[0].material.map.source
    assert_equal [0.25, 0.5], loaded.children[0].material.map.offset.to_a
    assert_equal [2, 3], loaded.children[0].material.map.repeat.to_a
    assert_equal [0.5, 0.5], loaded.children[0].material.map.center.to_a
    assert_equal 0.35, loaded.children[0].material.map.rotation
    assert_equal [1, 2, 3], loaded.children[0].position.to_a
    assert_equal [2, 2, 2], loaded.children[1].scale.to_a
    assert_equal 1 << 2, loaded.children[1].layers.mask
    assert_same loaded.children[0].geometry, loaded.children[1].geometry
    assert_same loaded.children[0].material, loaded.children[1].material
    assert_same loaded.children[0].material.map, loaded.children[1].material.map
  end

  def test_parse_reconstructs_scene_texture_camera_light_and_instanced_mesh
    scene = Three::Scene.new
    scene.background = Three::CubeTexture.new(%w[/px.png /nx.png /py.png /ny.png /pz.png /nz.png])
    camera = Three::PerspectiveCamera.new(60, aspect: 1.5, near: 0.2, far: 500)
    camera.zoom = 1.25
    light = Three::DirectionalLight.new(0xffddaa, 1.4)
    light.cast_shadow = true
    light.shadow_map_size = [1024, 1024]
    light.set_shadow_camera(left: -2, right: 2)
    instanced = Three::InstancedMesh.new(Three::PlaneGeometry.new(2, 2), Three::MeshLambertMaterial.new(color: 0xffffff), 2)
    matrix = Three::Matrix4.new.make_translation(1, 0, 0)
    instanced.count = 1
    instanced.set_matrix_at(1, matrix)
    instanced.set_color_at(1, [0.2, 0.4, 0.6])
    scene.add(camera, light, instanced)

    loaded = Three::Loaders::ThreeJSONLoader.new.parse(Three::Exporters::ThreeJSONExporter.new.export(scene))
    loaded_camera = loaded.children.find { |child| child.is_a?(Three::PerspectiveCamera) }
    loaded_light = loaded.children.find { |child| child.is_a?(Three::DirectionalLight) }
    loaded_instanced = loaded.children.find { |child| child.is_a?(Three::InstancedMesh) }

    assert_instance_of Three::CubeTexture, loaded.background
    assert_equal scene.background.sources, loaded.background.sources
    assert_equal 60, loaded_camera.fov
    assert_equal 1.5, loaded_camera.aspect
    assert_equal 0.2, loaded_camera.near
    assert_equal 500, loaded_camera.far
    assert_equal 1.25, loaded_camera.zoom
    assert_equal 0xffddaa, loaded_light.color.hex
    assert_equal 1.4, loaded_light.intensity
    assert loaded_light.cast_shadow
    assert_equal [1024, 1024], loaded_light.shadow_map_size
    assert_equal(-2, loaded_light.shadow_camera[:left])
    assert_equal 2, loaded_light.shadow_camera[:right]
    assert_equal 1, loaded_instanced.count
    assert_equal 2, loaded_instanced.capacity
    assert_instance_of Three::PlaneGeometry, loaded_instanced.geometry
    assert_equal matrix, loaded_instanced.get_matrix_at(1)
    assert_equal Three::Color.new(0.2, 0.4, 0.6), loaded_instanced.get_color_at(1)
  end

  def test_parse_reconstructs_generic_buffer_geometry
    geometry = Three::BufferGeometry.new
    geometry.set_index([0, 1, 2])
    geometry.set_attribute(:position, Three::Float32BufferAttribute.new([0, 0, 0, 1, 0, 0, 0, 1, 0], 3))
    material = Three::MeshNormalMaterial.new(flat_shading: true)
    scene = Three::Scene.new
    scene.add(Three::Mesh.new(geometry, material))

    loaded = Three::Loaders::ThreeJSONLoader.new.parse(scene.to_json)
    loaded_geometry = loaded.children.first.geometry

    assert_instance_of Three::BufferGeometry, loaded_geometry
    assert_equal :uint16, loaded_geometry.index.component_type
    assert_equal :float32, loaded_geometry.get_attribute(:position).component_type
    assert_equal [0, 1, 2], loaded_geometry.index.array
    assert_equal [0, 0, 0, 1, 0, 0, 0, 1, 0], loaded_geometry.get_attribute(:position).array
    assert_instance_of Three::MeshNormalMaterial, loaded.children.first.material
    assert loaded.children.first.material.flat_shading
  end

  def test_parse_reconstructs_line_and_points
    scene = Three::Scene.new
    texture = Three::Texture.new("/points.png")
    geometry = Three::BufferGeometry.new
    geometry.set_attribute(:position, Three::Float32BufferAttribute.new([0, 0, 0, 1, 0, 0, 0, 1, 0], 3))
    line = Three::Line.new(geometry, Three::LineBasicMaterial.new(color: 0xff8844, linewidth: 2))
    points = Three::Points.new(geometry, Three::PointsMaterial.new(color: 0x66ddff, map: texture, size: 0.5, size_attenuation: false))
    scene.add(line, points)

    loaded = Three::Loaders::ThreeJSONLoader.new.parse(scene.to_json)
    loaded_line = loaded.children[0]
    loaded_points = loaded.children[1]

    assert_instance_of Three::Line, loaded_line
    assert_instance_of Three::LineBasicMaterial, loaded_line.material
    assert_equal 0xff8844, loaded_line.material.color.hex
    assert_equal 2, loaded_line.material.linewidth
    assert_instance_of Three::Points, loaded_points
    assert_instance_of Three::PointsMaterial, loaded_points.material
    assert_equal 0x66ddff, loaded_points.material.color.hex
    assert_equal "/points.png", loaded_points.material.map.source
    assert_equal 0.5, loaded_points.material.size
    refute loaded_points.material.size_attenuation
    assert_same loaded_line.geometry, loaded_points.geometry
  end
end
