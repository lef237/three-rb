# frozen_string_literal: true

require_relative "../../../lib/three"

Three::Browser.run(starting: "Starting primitives scene") do |app|
  scene = Three::Scene.new
  camera = Three::PerspectiveCamera.new(55, aspect: 1.0, near: 0.1, far: 100)
  camera.position.z = 4

  line_geometry = Three::BufferGeometry.new
  line_geometry.set_attribute(
    :position,
    Three::Float32BufferAttribute.new(
      [
        -1.8, -0.8, 0,
        -0.9, 0.75, 0,
        0.0, -0.15, 0,
        0.9, 0.75, 0,
        1.8, -0.8, 0
      ],
      3
    )
  )
  line = Three::Line.new(line_geometry, Three::LineBasicMaterial.new(color: 0x66ddff, linewidth: 2))

  points_geometry = Three::BufferGeometry.new
  points_geometry.set_attribute(
    :position,
    Three::Float32BufferAttribute.new(
      [
        -1.3, 0.25, 0.15,
        -0.65, -0.35, 0.25,
        0.0, 0.45, -0.2,
        0.65, -0.35, 0.25,
        1.3, 0.25, 0.15,
        0.0, -0.9, 0
      ],
      3
    )
  )
  points = Three::Points.new(
    points_geometry,
    Three::PointsMaterial.new(color: 0xffcc4d, size: 12, size_attenuation: false)
  )

  sprite_texture = Three::Loaders::TextureLoader.new.load("/examples/browser/assets/checker.svg")
  sprite_material = Three::SpriteMaterial.new(
    color: 0xffffff,
    map: sprite_texture,
    rotation: 0.2,
    size_attenuation: false,
    opacity: 0.82
  )
  sprite = Three::Sprite.new(sprite_material)
  sprite.center = [0.5, 0.5]
  sprite.position.set(1.45, -0.95, 0.2)
  sprite.scale.set(0.42, 0.42, 1)

  scene.add(line, points, sprite)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x101418, 1)

  app.resize_renderer(renderer, camera)
  renderer.render(scene, camera)
  app.expose(
    {
      renderer: renderer,
      scene: scene,
      camera: camera,
      line: line,
      points: points,
      sprite: sprite,
      sprite_material: sprite_material,
      sprite_texture: sprite_texture,
      primitives_frame: 0
    },
    renderer: renderer
  )

  renderer.animation_loop do
    app.increment(:primitives_frame)
    line.rotation.z += 0.004
    points.rotation.y += 0.012
    sprite_material.rotation += 0.01
    renderer.render(scene, camera)
  end
end
