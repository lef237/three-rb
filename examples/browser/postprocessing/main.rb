# frozen_string_literal: true

require_relative "../../../lib/three"

Three::Browser.run(starting: "Starting postprocessing scene") do |app|
  scene = Three::Scene.new
  camera = Three::PerspectiveCamera.new(52, aspect: 1.0, near: 0.1, far: 100)
  camera.position.set(0, 0.15, 5.2)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x0a0d12, 1)

  composer = Three::Postprocessing::EffectComposer.new(renderer: renderer)
  render_pass = Three::Postprocessing::RenderPass.new(scene, camera, composer: composer)
  bloom_pass = Three::Postprocessing::UnrealBloomPass.new(
    resolution: [1, 1],
    strength: 1.15,
    radius: 0.42,
    threshold: 0.22,
    composer: composer
  )
  dot_screen_pass = Three::Postprocessing::DotScreenPass.new(
    center: [0.5, 0.5],
    angle: 0.72,
    scale: 1.4,
    composer: composer
  )
  output_pass = Three::Postprocessing::OutputPass.new(composer: composer)
  composer.add_pass(render_pass)
  composer.add_pass(bloom_pass)
  composer.add_pass(dot_screen_pass)
  composer.add_pass(output_pass)

  core_material = Three::MeshBasicMaterial.new(color: 0xf8fbff)
  core = Three::Mesh.new(Three::SphereGeometry.new(0.48, width_segments: 32, height_segments: 16), core_material)
  scene.add(core)

  ring_material = Three::MeshBasicMaterial.new(color: 0x4ed08f)
  ring = Three::Mesh.new(Three::BoxGeometry.new(2.15, 0.035, 0.035), ring_material)
  ring.position.z = -0.05
  scene.add(ring)

  accent_material = Three::MeshBasicMaterial.new(color: 0xffcc4d)
  left_accent = Three::Mesh.new(Three::BoxGeometry.new(0.18, 0.18, 0.18), accent_material)
  left_accent.position.set(-1.25, -0.52, 0.15)
  scene.add(left_accent)

  right_accent = Three::Mesh.new(Three::BoxGeometry.new(0.18, 0.18, 0.18), accent_material)
  right_accent.position.set(1.25, 0.52, 0.15)
  scene.add(right_accent)

  app.on_resize do |width, height, aspect|
    camera.aspect = aspect
    camera.update_projection_matrix
    renderer.set_size(width, height)
    composer.set_size(width, height)
  end
  composer.render(scene, camera)

  app.expose(
    {
      renderer: renderer,
      post_composer: composer,
      post_render_pass: render_pass,
      post_bloom_pass: bloom_pass,
      post_dot_screen_pass: dot_screen_pass,
      post_output_pass: output_pass,
      scene: scene,
      camera: camera,
      post_core: core,
      post_ring: ring,
      post_left_accent: left_accent,
      post_right_accent: right_accent,
      post_frame: 0
    },
    renderer: renderer
  )

  renderer.animation_loop do
    frame = app.increment(:post_frame)

    core.rotation.y += 0.014
    ring.rotation.z += 0.01
    left_accent.rotation.x += 0.018
    left_accent.rotation.y += 0.013
    right_accent.rotation.x -= 0.014
    right_accent.rotation.y += 0.017
    bloom_pass.strength = 0.95 + (0.22 * ((Math.sin(frame * 0.035) + 1) / 2.0))
    dot_screen_pass.scale = 1.35 + (0.18 * ((Math.sin(frame * 0.025) + 1) / 2.0))

    composer.render(scene, camera)
  end
end
