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

  def test_parse_reconstructs_resource_user_data_and_geometry_draw_range
    scene = Three::Scene.new
    texture = Three::Texture.new("/texture.png")
    texture.user_data = { "role" => "albedo" }
    geometry = Three::BufferGeometry.new
    geometry.user_data = { "role" => "partial-geometry" }
    geometry.set_draw_range(1, 2)
    geometry.set_attribute(:position, Three::Float32BufferAttribute.new([0, 0, 0, 1, 0, 0, 0, 1, 0], 3))
    material = Three::MeshBasicMaterial.new(map: texture)
    material.user_data = { "role" => "surface" }
    scene.add(Three::Mesh.new(geometry, material))

    loaded = Three::Loaders::ThreeJSONLoader.new.parse(scene.to_json)
    loaded_geometry = loaded.children.first.geometry
    loaded_material = loaded.children.first.material

    assert_equal({ start: 1, count: 2 }, loaded_geometry.draw_range)
    assert_equal({ "role" => "partial-geometry" }, loaded_geometry.user_data)
    assert_equal({ "role" => "surface" }, loaded_material.user_data)
    assert_equal({ "role" => "albedo" }, loaded_material.map.user_data)
  end

  def test_parse_reconstructs_rgbe_texture_resources
    scene = Three::Scene.new
    scene.environment = Three::RGBETexture.new("/studio.hdr")

    loaded = Three::Loaders::ThreeJSONLoader.new.parse(Three::Exporters::ThreeJSONExporter.new.export(scene))

    assert_instance_of Three::RGBETexture, loaded.environment
    assert_equal "/studio.hdr", loaded.environment.source
    assert_equal Three::EquirectangularReflectionMapping, loaded.environment.mapping
    assert_equal Three::LinearSRGBColorSpace, loaded.environment.color_space
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

  def test_parse_reconstructs_mesh_physical_material
    scene = Three::Scene.new
    texture = Three::Texture.new("/texture.png")
    anisotropy_map = Three::Texture.new("/anisotropy.png")
    clearcoat_map = Three::Texture.new("/clearcoat.png")
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
      ior: 1.45,
      reflectivity: 0.35,
      iridescence: 0.2,
      iridescence_ior: 1.15,
      iridescence_thickness_range: [120, 360],
      sheen: 0.3,
      sheen_color: 0x223344,
      sheen_roughness: 0.65,
      dispersion: 0.1,
      specular_intensity: 0.7,
      specular_color: 0xf0f6ff,
      attenuation_distance: 5,
      attenuation_color: 0x88aaff,
      map: texture
    )
    scene.add(Three::Mesh.new(Three::BoxGeometry.new, material))

    loaded = Three::Loaders::ThreeJSONLoader.new.parse(Three::Exporters::ThreeJSONExporter.new.export(scene))
    loaded_material = loaded.children.first.material

    assert_instance_of Three::MeshPhysicalMaterial, loaded_material
    assert_equal 0x99ccff, loaded_material.color.hex
    assert_equal 0.35, loaded_material.roughness
    assert_equal 0.1, loaded_material.metalness
    assert_equal 0.4, loaded_material.anisotropy
    assert_equal 0.2, loaded_material.anisotropy_rotation
    assert_equal "/anisotropy.png", loaded_material.anisotropy_map.source
    assert_equal 0.8, loaded_material.clearcoat
    assert_equal 0.25, loaded_material.clearcoat_roughness
    assert_equal "/clearcoat.png", loaded_material.clearcoat_map.source
    assert_equal 0.2, loaded_material.transmission
    assert_equal 0.1, loaded_material.thickness
    assert_in_delta 1.3255813953488373, loaded_material.ior
    assert_equal 0.35, loaded_material.reflectivity
    assert_equal 0.2, loaded_material.iridescence
    assert_equal 1.15, loaded_material.iridescence_ior
    assert_equal [120, 360], loaded_material.iridescence_thickness_range
    assert_equal 0.3, loaded_material.sheen
    assert_equal 0x223344, loaded_material.sheen_color.hex
    assert_equal 0.65, loaded_material.sheen_roughness
    assert_equal 0.1, loaded_material.dispersion
    assert_equal 0.7, loaded_material.specular_intensity
    assert_equal 0xf0f6ff, loaded_material.specular_color.hex
    assert_equal 5, loaded_material.attenuation_distance
    assert_equal 0x88aaff, loaded_material.attenuation_color.hex
    assert_equal "/texture.png", loaded_material.map.source
  end

  def test_parse_reconstructs_mesh_matcap_material
    scene = Three::Scene.new
    matcap = Three::Texture.new("/matcap.png")
    texture = Three::Texture.new("/texture.png")
    material = Three::MeshMatcapMaterial.new(color: 0x99ccff, matcap: matcap, map: texture, flat_shading: true)
    scene.add(Three::Mesh.new(Three::SphereGeometry.new, material))

    loaded = Three::Loaders::ThreeJSONLoader.new.parse(Three::Exporters::ThreeJSONExporter.new.export(scene))
    loaded_material = loaded.children.first.material

    assert_instance_of Three::MeshMatcapMaterial, loaded_material
    assert_equal 0x99ccff, loaded_material.color.hex
    assert_equal "/matcap.png", loaded_material.matcap.source
    assert_equal "/texture.png", loaded_material.map.source
    assert loaded_material.flat_shading
  end

  def test_parse_reconstructs_mesh_toon_material
    scene = Three::Scene.new
    texture = Three::Texture.new("/texture.png")
    gradient_map = Three::Texture.new("/gradient.png")
    material = Three::MeshToonMaterial.new(color: 0x99ccff, emissive: 0x101820, map: texture, gradient_map: gradient_map, flat_shading: true)
    scene.add(Three::Mesh.new(Three::SphereGeometry.new, material))

    loaded = Three::Loaders::ThreeJSONLoader.new.parse(Three::Exporters::ThreeJSONExporter.new.export(scene))
    loaded_material = loaded.children.first.material

    assert_instance_of Three::MeshToonMaterial, loaded_material
    assert_equal 0x99ccff, loaded_material.color.hex
    assert_equal 0x101820, loaded_material.emissive.hex
    assert_equal "/texture.png", loaded_material.map.source
    assert_equal "/gradient.png", loaded_material.gradient_map.source
    assert loaded_material.flat_shading
  end

  def test_parse_reconstructs_shadow_material
    scene = Three::Scene.new
    material = Three::ShadowMaterial.new(color: 0x112233, opacity: 0.32, fog: false)
    scene.add(Three::Mesh.new(Three::PlaneGeometry.new, material))

    loaded = Three::Loaders::ThreeJSONLoader.new.parse(Three::Exporters::ThreeJSONExporter.new.export(scene))
    loaded_material = loaded.children.first.material

    assert_instance_of Three::ShadowMaterial, loaded_material
    assert_equal 0x112233, loaded_material.color.hex
    assert_equal 0.32, loaded_material.opacity
    assert loaded_material.transparent
    refute loaded_material.fog
  end

  def test_parse_reconstructs_sprite_material_and_object
    scene = Three::Scene.new
    material = Three::SpriteMaterial.new(color: 0xffcc4d, map: Three::Texture.new("/sprite.png"), rotation: 0.25, size_attenuation: false)
    sprite = Three::Sprite.new(material)
    sprite.center = [0.25, 0.75]
    scene.add(sprite)

    loaded = Three::Loaders::ThreeJSONLoader.new.parse(Three::Exporters::ThreeJSONExporter.new.export(scene))
    loaded_sprite = loaded.children.first
    loaded_material = loaded_sprite.material

    assert_instance_of Three::Sprite, loaded_sprite
    assert_equal [0.25, 0.75], loaded_sprite.center.to_a
    assert_instance_of Three::SpriteMaterial, loaded_material
    assert_equal 0xffcc4d, loaded_material.color.hex
    assert_equal "/sprite.png", loaded_material.map.source
    assert_equal 0.25, loaded_material.rotation
    refute loaded_material.size_attenuation
  end
end
