# frozen_string_literal: true

require_relative "../../../lib/three"

Three::Browser.run(starting: "Starting Ruby scene") do |app|
  scene = Three::Scene.new
  camera = Three::PerspectiveCamera.new(45, aspect: 1.0, near: 0.1, far: 100)
  camera.position.set(0, 0.15, 4.0)

  scene.add(Three::AmbientLight.new(0xffffff, 0.65))

  key_light = Three::DirectionalLight.new(0xffffff, 1.0)
  key_light.position.set(2.5, 3.0, 4.0)
  scene.add(key_light)

  renderer = Three::Renderers::ThreeJSRenderer.new(
    canvas: "#scene",
    antialias: true,
    alpha: false,
    preserveDrawingBuffer: true
  )
  renderer.set_clear_color(0x11151a, 1)

  gltf = Three::Loaders::GLTFLoader.new(backend: renderer.backend).load("/examples/browser/gltf/assets/animated_triangle.gltf")
  model = gltf.scene
  model.position.x = -0.75
  model.scale.set(1.2, 1.2, 1.2)
  scene.add(model)

  draco_decoder_path = "/node_modules/three/examples/jsm/libs/draco/gltf/"
  compressed_gltf = Three::Loaders::GLTFLoader.new(
    backend: renderer.backend,
    draco_decoder_path: draco_decoder_path
  ).load("/examples/browser/gltf/assets/compressed_triangle.gltf")
  compressed_model = compressed_gltf.scene
  compressed_model.position.x = 1.05
  compressed_model.scale.set(0.82, 0.82, 0.82)
  scene.add(compressed_model)

  clock = Three::Clock.new
  mixer = Three::AnimationMixer.new(model, backend: renderer.backend)
  action = mixer.clip_action(gltf.animations.first)
  action.play

  app.resize_renderer(renderer, camera)
  renderer.render(scene, camera)

  app.expose(
    {
      renderer: renderer,
      gltf_root_scene: scene,
      camera: camera,
      gltf_scene: model,
      compressed_gltf_scene: compressed_model,
      compressed_gltf_decoder_path: draco_decoder_path,
      gltf_animations: gltf.animations.length,
      gltf_animation_name: gltf.animations.first&.name,
      gltf_animation_duration: gltf.animations.first&.duration,
      gltf_mixer: mixer,
      gltf_action: action,
      gltf_frame: 0,
      gltf_animation_time: 0
    },
    renderer: renderer
  )
  app.set(:dispose_gltf, proc do
    mixer.stop_all_action
    mixer.uncache_root
    renderer.dispose_subtree(model, remove: true, dispose_textures: true)
    renderer.dispose_subtree(compressed_model, remove: true, dispose_textures: true)
    app.set(:gltf_disposed, true)
  end)

  frame = 0
  animation_time = 0
  renderer.animation_loop do
    frame += 1
    delta = clock.get_delta
    mixer.update(delta)
    animation_time += delta
    app.set(:gltf_animation_time, animation_time)
    app.set(:gltf_frame, frame)
    renderer.render(scene, camera)
  end
end
