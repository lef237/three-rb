# frozen_string_literal: true

require "json"

module SceneFixtureBuilder
  module_function

  def build_serialization_scene
    scene = Three::Scene.new
    scene.name = "fixture-scene"
    scene.user_data = { "purpose" => "json-regression", "version" => 1 }
    scene.environment = Three::RGBETexture.new("/fixtures/studio.hdr")

    camera = Three::PerspectiveCamera.new(55, aspect: 16.0 / 9.0, near: 0.2, far: 250)
    camera.name = "main-camera"
    camera.position.set(0, 1.4, 6)
    camera.zoom = 1.1
    scene.add(camera)

    ambient = Three::AmbientLight.new(0x445566, 0.35)
    ambient.name = "ambient-fill"
    scene.add(ambient)

    key_light = Three::DirectionalLight.new(0xffe0bb, 1.7)
    key_light.name = "key-light"
    key_light.position.set(3, 4, 5)
    key_light.cast_shadow = true
    key_light.shadow_map_size = [1024, 1024]
    key_light.shadow_bias = -0.0002
    key_light.set_shadow_camera(left: -4, right: 4, top: 3, bottom: -3, near: 0.5, far: 20)
    scene.add(key_light)

    rig = Three::Group.new
    rig.name = "fixture-rig"
    rig.position.set(0.5, 0, -0.25)
    scene.add(rig)

    checker = Three::Texture.new(
      "/fixtures/checker.png",
      wrap_s: Three::RepeatWrapping,
      wrap_t: Three::RepeatWrapping,
      mag_filter: Three::NearestFilter,
      min_filter: Three::NearestMipmapNearestFilter,
      offset: [0.125, 0.25],
      repeat: [3, 2],
      center: [0.5, 0.5],
      rotation: 0.35
    )
    clearcoat = Three::Texture.new("/fixtures/clearcoat.png")
    specular = Three::Texture.new("/fixtures/specular.png")
    material = Three::MeshPhysicalMaterial.new(
      color: 0x99ccff,
      roughness: 0.38,
      metalness: 0.12,
      anisotropy: 0.25,
      anisotropy_rotation: 0.15,
      clearcoat: 0.7,
      clearcoat_roughness: 0.2,
      clearcoat_map: clearcoat,
      transmission: 0.05,
      thickness: 0.08,
      ior: 1.45,
      sheen: 0.18,
      sheen_color: 0x223344,
      sheen_roughness: 0.65,
      specular_intensity: 0.75,
      specular_color: 0xf0f6ff,
      specular_color_map: specular,
      map: checker,
      roughness_map: checker
    )
    cube = Three::Mesh.new(Three::BoxGeometry.new(1.2, 0.8, 0.6, width_segments: 2), material)
    cube.name = "physical-cube"
    cube.position.set(-0.8, 0.25, 0)
    cube.cast_shadow = true
    cube.receive_shadow = true
    rig.add(cube)

    primitive_geometry = Three::BufferGeometry.new
    primitive_geometry.name = "shared-primitive-geometry"
    primitive_geometry.set_attribute(
      :position,
      Three::Float32BufferAttribute.new(
        [
          -1.2, -0.6, 0,
          -0.4, 0.7, 0.1,
          0.4, -0.2, -0.1,
          1.2, 0.55, 0
        ],
        3
      )
    )
    line = Three::Line.new(primitive_geometry, Three::LineBasicMaterial.new(color: 0xff8844, linewidth: 2))
    line.name = "fixture-line"
    points = Three::Points.new(
      primitive_geometry,
      Three::PointsMaterial.new(color: 0x66ddff, map: checker, size: 0.35, size_attenuation: false)
    )
    points.name = "fixture-points"
    rig.add(line, points)

    instanced = Three::InstancedMesh.new(
      Three::PlaneGeometry.new(0.3, 0.3),
      Three::MeshLambertMaterial.new(color: 0xffffff, map: checker),
      3
    )
    instanced.name = "fixture-instanced"
    instanced.count = 2
    instanced.set_matrix_at(0, Three::Matrix4.new.make_translation(-1.0, -0.8, 0.2))
    instanced.set_matrix_at(1, Three::Matrix4.new.make_translation(0.0, -0.8, 0.2))
    instanced.set_matrix_at(2, Three::Matrix4.new.make_translation(1.0, -0.8, 0.2))
    instanced.set_color_at(0, [0.25, 0.55, 0.9])
    instanced.set_color_at(1, [0.9, 0.7, 0.25])
    instanced.set_color_at(2, [0.45, 0.9, 0.55])
    scene.add(instanced)

    scene
  end

  def export_serialization_scene
    Three::Exporters::ThreeJSONExporter.new(deterministic_ids: true).export(build_serialization_scene)
  end

  def serialization_fixture_json
    "#{JSON.pretty_generate(export_serialization_scene)}\n"
  end
end
