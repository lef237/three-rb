# frozen_string_literal: true

require "test_helper"
require "json"

class ThreeThreeJSONExporterTest < Minitest::Test
  def test_exports_scene_graph_with_deduplicated_resources
    scene = Three::Scene.new
    scene.name = "root"
    texture = Three::Texture.new("/texture.png", offset: [0.25, 0.5], repeat: [2, 3], center: [0.5, 0.5], rotation: 0.35)
    geometry = Three::BoxGeometry.new(1, 2, 3)
    material = Three::MeshBasicMaterial.new(color: 0x00ff00, map: texture)
    first = Three::Mesh.new(geometry, material)
    second = Three::Mesh.new(geometry, material)
    first.position.set(1, 2, 3)
    second.scale.set(2, 2, 2)
    second.layers.set(2)
    scene.add(first, second)

    exported = Three::Exporters::ThreeJSONExporter.new.export(scene)

    assert_equal({ version: 1, generator: "three.rb", type: "Object" }, exported[:metadata])
    assert_equal "Scene", exported[:object][:type]
    assert_equal "root", exported[:object][:name]
    assert_equal 2, exported[:object][:children].length
    assert_equal [1, 2, 3], exported[:object][:children][0][:position]
    assert_equal [2, 2, 2], exported[:object][:children][1][:scale]
    assert_equal 1 << 2, exported[:object][:children][1][:layers]

    assert_equal [geometry.uuid], exported[:geometries].map { |entry| entry[:uuid] }
    assert_equal [material.uuid], exported[:materials].map { |entry| entry[:uuid] }
    assert_equal [texture.uuid], exported[:textures].map { |entry| entry[:uuid] }
    assert_equal geometry.uuid, exported[:object][:children][0][:geometry]
    assert_equal material.uuid, exported[:object][:children][0][:material]
    assert_equal texture.uuid, exported[:materials][0][:map]
    assert_equal "/texture.png", exported[:textures][0][:source]
    assert_equal [0.25, 0.5], exported[:textures][0][:offset]
    assert_equal [2, 3], exported[:textures][0][:repeat]
    assert_equal [0.5, 0.5], exported[:textures][0][:center]
    assert_equal 0.35, exported[:textures][0][:rotation]
  end

  def test_exports_cameras_lights_scene_textures_and_instanced_mesh_data
    scene = Three::Scene.new
    scene.background = Three::CubeTexture.new(%w[/px.png /nx.png /py.png /ny.png /pz.png /nz.png])
    camera = Three::PerspectiveCamera.new(60, aspect: 1.5, near: 0.2, far: 500)
    light = Three::DirectionalLight.new(0xffddaa, 1.4)
    light.cast_shadow = true
    light.set_shadow_camera(left: -2, right: 2)
    instanced = Three::InstancedMesh.new(Three::PlaneGeometry.new(2, 2), Three::MeshLambertMaterial.new(color: 0xffffff), 2)
    matrix = Three::Matrix4.new.make_translation(1, 0, 0)
    instanced.set_matrix_at(1, matrix)
    instanced.set_color_at(1, [0.2, 0.4, 0.6])
    scene.add(camera, light, instanced)

    exported = Three::Exporters::ThreeJSONExporter.new.export(scene)
    children = exported[:object][:children]

    assert_equal scene.background.uuid, exported[:object][:background]
    assert_equal [scene.background.uuid], exported[:textures].map { |entry| entry[:uuid] }

    camera_data = children.find { |entry| entry[:type] == "PerspectiveCamera" }
    assert_equal 60, camera_data[:fov]
    assert_equal 1.5, camera_data[:aspect]
    assert_equal 0.2, camera_data[:near]
    assert_equal 500, camera_data[:far]

    light_data = children.find { |entry| entry[:type] == "DirectionalLight" }
    assert_equal 0xffddaa, light_data[:color]
    assert_equal 1.4, light_data[:intensity]
    assert_equal true, light_data[:cast_shadow]
    assert_equal(-2, light_data[:shadow_camera][:left])
    assert_equal 2, light_data[:shadow_camera][:right]

    instanced_data = children.find { |entry| entry[:type] == "InstancedMesh" }
    assert_equal 2, instanced_data[:count]
    assert_equal 2, instanced_data[:capacity]
    assert_equal matrix.to_a, instanced_data[:instance_matrices][1]
    assert_equal [0.2, 0.4, 0.6], instanced_data[:instance_colors][1]
  end

  def test_exports_line_and_points_resources
    scene = Three::Scene.new
    geometry = Three::BufferGeometry.new
    geometry.set_attribute(:position, Three::Float32BufferAttribute.new([0, 0, 0, 1, 0, 0, 0, 1, 0], 3))
    line_material = Three::LineBasicMaterial.new(color: 0xff8844, linewidth: 2)
    points_material = Three::PointsMaterial.new(color: 0x66ddff, size: 0.5)
    scene.add(
      Three::Line.new(geometry, line_material),
      Three::Points.new(geometry, points_material)
    )

    exported = Three::Exporters::ThreeJSONExporter.new.export(scene)
    children = exported[:object][:children]

    assert_equal %w[Line Points], children.map { |entry| entry[:type] }
    assert_equal [geometry.uuid], exported[:geometries].map { |entry| entry[:uuid] }
    assert_equal [line_material.uuid, points_material.uuid], exported[:materials].map { |entry| entry[:uuid] }
    assert_equal geometry.uuid, children[0][:geometry]
    assert_equal geometry.uuid, children[1][:geometry]
    assert_equal line_material.uuid, children[0][:material]
    assert_equal points_material.uuid, children[1][:material]
    assert_equal "LineBasicMaterial", exported[:materials][0][:type]
    assert_equal "PointsMaterial", exported[:materials][1][:type]
  end

  def test_exports_rgbe_texture_resources
    scene = Three::Scene.new
    scene.environment = Three::RGBETexture.new("/studio.hdr")

    exported = Three::Exporters::ThreeJSONExporter.new.export(scene)
    texture_data = exported[:textures].first

    assert_equal "RGBETexture", texture_data[:type]
    assert_equal "/studio.hdr", texture_data[:source]
    assert_equal Three::EquirectangularReflectionMapping, texture_data[:mapping]
    assert_equal Three::LinearSRGBColorSpace, texture_data[:color_space]
    assert_equal texture_data[:uuid], exported[:object][:environment]
  end

  def test_exports_mesh_physical_material_resources
    scene = Three::Scene.new
    texture = Three::Texture.new("/texture.png")
    anisotropy_map = Three::Texture.new("/anisotropy.png")
    clearcoat_map = Three::Texture.new("/clearcoat.png")
    specular_color_map = Three::Texture.new("/specular-color.png")
    material = Three::MeshPhysicalMaterial.new(
      color: 0x99ccff,
      roughness: 0.35,
      metalness: 0.1,
      anisotropy: 0.4,
      anisotropy_rotation: 0.2,
      anisotropy_map: anisotropy_map,
      clearcoat: 0.8,
      clearcoat_roughness: 0.25,
      clearcoat_map: clearcoat_map,
      transmission: 0.2,
      thickness: 0.1,
      dispersion: 0.05,
      specular_intensity: 0.7,
      specular_color: 0xf0f6ff,
      specular_color_map: specular_color_map,
      map: texture
    )
    scene.add(Three::Mesh.new(Three::BoxGeometry.new, material))

    exported = Three::Exporters::ThreeJSONExporter.new.export(scene)
    material_data = exported[:materials].first

    assert_equal "MeshPhysicalMaterial", material_data[:type]
    assert_equal 0x99ccff, material_data[:color]
    assert_equal 0.4, material_data[:anisotropy]
    assert_equal 0.2, material_data[:anisotropy_rotation]
    assert_equal anisotropy_map.uuid, material_data[:anisotropy_map]
    assert_equal 0.8, material_data[:clearcoat]
    assert_equal 0.25, material_data[:clearcoat_roughness]
    assert_equal clearcoat_map.uuid, material_data[:clearcoat_map]
    assert_equal 0.2, material_data[:transmission]
    assert_equal 0.1, material_data[:thickness]
    assert_equal 0.05, material_data[:dispersion]
    assert_equal 0.7, material_data[:specular_intensity]
    assert_equal 0xf0f6ff, material_data[:specular_color]
    assert_equal specular_color_map.uuid, material_data[:specular_color_map]
    assert_equal [texture.uuid, anisotropy_map.uuid, clearcoat_map.uuid, specular_color_map.uuid], exported[:textures].map { |entry| entry[:uuid] }
  end

  def test_exports_mesh_matcap_material_resources
    scene = Three::Scene.new
    matcap = Three::Texture.new("/matcap.png")
    texture = Three::Texture.new("/texture.png")
    material = Three::MeshMatcapMaterial.new(color: 0x99ccff, matcap: matcap, map: texture, flat_shading: true)
    scene.add(Three::Mesh.new(Three::SphereGeometry.new, material))

    exported = Three::Exporters::ThreeJSONExporter.new.export(scene)
    material_data = exported[:materials].first

    assert_equal "MeshMatcapMaterial", material_data[:type]
    assert_equal 0x99ccff, material_data[:color]
    assert_equal matcap.uuid, material_data[:matcap]
    assert_equal texture.uuid, material_data[:map]
    assert material_data[:flat_shading]
    assert_equal [matcap.uuid, texture.uuid], exported[:textures].map { |entry| entry[:uuid] }
  end

  def test_exports_mesh_toon_material_resources
    scene = Three::Scene.new
    texture = Three::Texture.new("/texture.png")
    gradient_map = Three::Texture.new("/gradient.png")
    material = Three::MeshToonMaterial.new(color: 0x99ccff, emissive: 0x101820, map: texture, gradient_map: gradient_map, flat_shading: true)
    scene.add(Three::Mesh.new(Three::SphereGeometry.new, material))

    exported = Three::Exporters::ThreeJSONExporter.new.export(scene)
    material_data = exported[:materials].first

    assert_equal "MeshToonMaterial", material_data[:type]
    assert_equal 0x99ccff, material_data[:color]
    assert_equal 0x101820, material_data[:emissive]
    assert_equal texture.uuid, material_data[:map]
    assert_equal gradient_map.uuid, material_data[:gradient_map]
    assert material_data[:flat_shading]
    assert_equal [texture.uuid, gradient_map.uuid], exported[:textures].map { |entry| entry[:uuid] }
  end

  def test_exports_shadow_material
    scene = Three::Scene.new
    material = Three::ShadowMaterial.new(color: 0x112233, opacity: 0.32, fog: false)
    scene.add(Three::Mesh.new(Three::PlaneGeometry.new, material))

    exported = Three::Exporters::ThreeJSONExporter.new.export(scene)
    material_data = exported[:materials].first

    assert_equal "ShadowMaterial", material_data[:type]
    assert_equal 0x112233, material_data[:color]
    assert_equal 0.32, material_data[:opacity]
    assert material_data[:transparent]
    refute material_data[:fog]
    assert_empty exported[:textures]
  end

  def test_object3d_to_json_uses_exporter_format
    scene = Three::Scene.new
    scene.add(Three::Mesh.new(Three::BoxGeometry.new, Three::MeshBasicMaterial.new))

    parsed = JSON.parse(scene.to_json)

    assert_equal "three.rb", parsed.fetch("metadata").fetch("generator")
    assert_equal "Scene", parsed.fetch("object").fetch("type")
    assert_equal 1, parsed.fetch("geometries").length
    assert_equal 1, parsed.fetch("materials").length
  end

  def test_deterministic_ids_make_equivalent_exports_equal
    build_scene = proc do
      scene = Three::Scene.new
      texture = Three::Texture.new("/texture.png")
      geometry = Three::BoxGeometry.new(1, 1, 1)
      material = Three::MeshBasicMaterial.new(color: 0x336699, map: texture)
      scene.add(Three::Mesh.new(geometry, material))
      scene
    end
    exporter = Three::Exporters::ThreeJSONExporter.new(deterministic_ids: true)

    first = exporter.export(build_scene.call)
    second = exporter.export(build_scene.call)

    assert_equal first, second
    assert_equal "object-0", first[:object][:uuid]
    assert_equal "object-1", first[:object][:children][0][:uuid]
    assert_equal "geometry-0", first[:geometries][0][:uuid]
    assert_equal "material-0", first[:materials][0][:uuid]
    assert_equal "texture-0", first[:textures][0][:uuid]
    assert_equal "geometry-0", first[:object][:children][0][:geometry]
    assert_equal "material-0", first[:object][:children][0][:material]
    assert_equal "texture-0", first[:materials][0][:map]
  end

  def test_export_rejects_non_object3d_roots
    assert_raises(TypeError) { Three::Exporters::ThreeJSONExporter.new.export(Three::BoxGeometry.new) }
  end
end
