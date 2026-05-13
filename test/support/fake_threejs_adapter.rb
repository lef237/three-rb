# frozen_string_literal: true

class FakeThreeJSAdapter
  TEXTURE_SLOTS = %i[
    map
    normalMap
    roughnessMap
    metalnessMap
    aoMap
    emissiveMap
    alphaMap
    bumpMap
    displacementMap
    envMap
    lightMap
    specularMap
    clearcoatMap
    clearcoatNormalMap
    clearcoatRoughnessMap
    transmissionMap
    thicknessMap
    iridescenceMap
    iridescenceThicknessMap
    sheenColorMap
    sheenRoughnessMap
    specularColorMap
    specularIntensityMap
  ].freeze

  attr_reader :calls
  attr_accessor :raycaster_intersections

  def initialize
    @calls = []
    @raycaster_intersections = []
  end

  def new_webgl_renderer(options = {})
    handle(:renderer, options: options, dom_element: handle(:dom_element))
  end

  def renderer_dom_element(renderer)
    renderer[:dom_element]
  end

  def set_renderer_size(renderer, width, height)
    @calls << [:set_renderer_size, renderer, width, height]
  end

  def set_clear_color(renderer, color, alpha = 1)
    @calls << [:set_clear_color, renderer, color, alpha]
  end

  def set_renderer_shadow_map(renderer, enabled: nil, type: nil, auto_update: nil)
    @calls << [:set_renderer_shadow_map, renderer, { enabled: enabled, type: type, auto_update: auto_update }]
    renderer[:shadow_map] ||= {}
    renderer[:shadow_map][:enabled] = enabled unless enabled.nil?
    renderer[:shadow_map][:type] = type unless type.nil?
    renderer[:shadow_map][:auto_update] = auto_update unless auto_update.nil?
  end

  def set_animation_loop(renderer, callback)
    @calls << [:set_animation_loop, renderer, callback]
  end

  def render(renderer, scene, camera)
    @calls << [:render, renderer, scene, camera]
  end

  def new_orbit_controls(camera, dom_element)
    handle(:orbit_controls, camera: camera, dom_element: dom_element, target: [0, 0, 0])
  end

  def new_raycaster
    handle(:raycaster)
  end

  def set_raycaster_from_camera(raycaster, coords, camera)
    @calls << [:set_raycaster_from_camera, raycaster, coords, camera]
    raycaster[:coords] = coords
    raycaster[:camera] = camera
  end

  def intersect_objects(raycaster, objects, recursive: false)
    @calls << [:intersect_objects, raycaster, objects, recursive]
    @raycaster_intersections
  end

  def load_texture(source, parameters = {})
    handle(:texture, { source: source }.merge(parameters))
  end

  def load_cube_texture(sources, parameters = {})
    handle(:cube_texture, { sources: sources.dup }.merge(parameters))
  end

  def load_gltf(source)
    handle(:gltf, source: source, scene: handle(:gltf_scene, children: []))
  end

  def update_texture(texture, parameters)
    @calls << [:update_texture, texture, parameters]
    texture.merge!(parameters)
  end

  def set_control_property(control, name, value)
    @calls << [:set_control_property, control, name, value]
    control[name.to_sym] = value
  end

  def set_orbit_controls_target(control, target)
    @calls << [:set_orbit_controls_target, control, target]
    control[:target] = target
  end

  def update_controls(control)
    @calls << [:update_controls, control]
  end

  def dispose_controls(control)
    @calls << [:dispose_controls, control]
  end

  def object_transform(object)
    [
      object[:position] || [0, 0, 0],
      object[:quaternion] || [0, 0, 0, 1],
      object[:scale] || [1, 1, 1]
    ]
  end

  def new_scene
    handle(:scene, children: [])
  end

  def new_group
    handle(:group, children: [])
  end

  def new_object3d
    handle(:object3d, children: [])
  end

  def new_perspective_camera(fov, aspect, near, far)
    handle(:perspective_camera, fov: fov, aspect: aspect, near: near, far: far, children: [])
  end

  def new_orthographic_camera(left, right, top, bottom, near, far)
    handle(:orthographic_camera, left: left, right: right, top: top, bottom: bottom, near: near, far: far, children: [])
  end

  def new_ambient_light(color, intensity)
    handle(:ambient_light, color: color, intensity: intensity, children: [])
  end

  def new_directional_light(color, intensity)
    handle(:directional_light, color: color, intensity: intensity, children: [], shadow: default_shadow)
  end

  def new_point_light(color, intensity, distance, decay)
    handle(:point_light, color: color, intensity: intensity, distance: distance, decay: decay, children: [], shadow: default_shadow)
  end

  def new_hemisphere_light(sky_color, ground_color, intensity)
    handle(:hemisphere_light, sky_color: sky_color, ground_color: ground_color, intensity: intensity, children: [])
  end

  def new_mesh(geometry, material)
    handle(:mesh, geometry: geometry, material: material, children: [])
  end

  def new_line(geometry, material)
    handle(:line, geometry: geometry, material: material, children: [])
  end

  def new_points(geometry, material)
    handle(:points, geometry: geometry, material: material, children: [])
  end

  def new_instanced_mesh(geometry, material, count)
    handle(
      :instanced_mesh,
      geometry: geometry,
      material: material,
      count: count,
      capacity: count,
      instance_matrices: Array.new(count),
      instance_colors: nil,
      children: []
    )
  end

  def set_object_geometry(object, geometry)
    @calls << [:set_object_geometry, object, geometry]
    object[:geometry] = geometry
  end

  def set_object_material(object, material)
    @calls << [:set_object_material, object, material]
    object[:material] = material
  end

  def set_mesh_geometry(mesh, geometry)
    @calls << [:set_mesh_geometry, mesh, geometry]
    mesh[:geometry] = geometry
  end

  def set_mesh_material(mesh, material)
    @calls << [:set_mesh_material, mesh, material]
    mesh[:material] = material
  end

  def set_object_layers(object, mask)
    @calls << [:set_object_layers, object, mask]
    object[:layers] = mask
  end

  def set_instanced_mesh_count(mesh, count)
    @calls << [:set_instanced_mesh_count, mesh, count]
    raise ArgumentError, "count cannot exceed capacity" if count > mesh[:capacity]

    mesh[:count] = count
  end

  def set_instanced_mesh_matrix_at(mesh, index, elements)
    @calls << [:set_instanced_mesh_matrix_at, mesh, index, elements]
    mesh[:instance_matrices][index] = elements.dup
  end

  def set_instanced_mesh_instance_matrix_needs_update(mesh, value)
    @calls << [:set_instanced_mesh_instance_matrix_needs_update, mesh, value]
    mesh[:instance_matrix_needs_update] = value
  end

  def set_instanced_mesh_color_at(mesh, index, color)
    @calls << [:set_instanced_mesh_color_at, mesh, index, color]
    mesh[:instance_colors] ||= Array.new(mesh[:capacity]) { [1, 1, 1] }
    mesh[:instance_colors][index] = color.dup
  end

  def set_instanced_mesh_instance_color_needs_update(mesh, value)
    @calls << [:set_instanced_mesh_instance_color_needs_update, mesh, value]
    mesh[:instance_color_needs_update] = value
  end

  def new_box_geometry(width, height, depth, width_segments, height_segments, depth_segments)
    handle(
      :box_geometry,
      width: width,
      height: height,
      depth: depth,
      width_segments: width_segments,
      height_segments: height_segments,
      depth_segments: depth_segments
    )
  end

  def new_plane_geometry(width, height, width_segments, height_segments)
    handle(
      :plane_geometry,
      width: width,
      height: height,
      width_segments: width_segments,
      height_segments: height_segments
    )
  end

  def new_sphere_geometry(radius, width_segments, height_segments, phi_start, phi_length, theta_start, theta_length)
    handle(
      :sphere_geometry,
      radius: radius,
      width_segments: width_segments,
      height_segments: height_segments,
      phi_start: phi_start,
      phi_length: phi_length,
      theta_start: theta_start,
      theta_length: theta_length
    )
  end

  def new_buffer_geometry
    handle(:buffer_geometry, attributes: {}, groups: [])
  end

  def new_buffer_attribute(component_type, array, item_size, normalized)
    handle(:buffer_attribute, component_type: component_type, array: array.dup, item_size: item_size, normalized: normalized)
  end

  def set_geometry_index(geometry, attribute)
    @calls << [:set_geometry_index, geometry, attribute]
    geometry[:index] = attribute
  end

  def set_geometry_attribute(geometry, name, attribute)
    @calls << [:set_geometry_attribute, geometry, name, attribute]
    geometry[:attributes][name] = attribute
  end

  def delete_geometry_attribute(geometry, name)
    @calls << [:delete_geometry_attribute, geometry, name]
    geometry[:attributes].delete(name)
  end

  def clear_geometry_groups(geometry)
    @calls << [:clear_geometry_groups, geometry]
    geometry[:groups].clear
  end

  def add_geometry_group(geometry, start, count, material_index)
    @calls << [:add_geometry_group, geometry, start, count, material_index]
    geometry[:groups] << { start: start, count: count, material_index: material_index }
  end

  def set_geometry_draw_range(geometry, start, count)
    @calls << [:set_geometry_draw_range, geometry, start, count]
    geometry[:draw_range] = { start: start, count: count }
  end

  def new_mesh_basic_material(parameters)
    handle(:mesh_basic_material, parameters: parameters.dup)
  end

  def new_line_basic_material(parameters)
    handle(:line_basic_material, parameters: parameters.dup)
  end

  def new_mesh_lambert_material(parameters)
    handle(:mesh_lambert_material, parameters: parameters.dup)
  end

  def new_mesh_normal_material(parameters)
    handle(:mesh_normal_material, parameters: parameters.dup)
  end

  def new_mesh_phong_material(parameters)
    handle(:mesh_phong_material, parameters: parameters.dup)
  end

  def new_mesh_standard_material(parameters)
    handle(:mesh_standard_material, parameters: parameters.dup)
  end

  def new_points_material(parameters)
    handle(:points_material, parameters: parameters.dup)
  end

  def set_object_name(object, name)
    @calls << [:set_object_name, object, name]
    object[:name] = name
  end

  def set_object_visible(object, visible)
    @calls << [:set_object_visible, object, visible]
    object[:visible] = visible
  end

  def set_object_shadow(object, cast_shadow, receive_shadow)
    @calls << [:set_object_shadow, object, cast_shadow, receive_shadow]
    object[:cast_shadow] = cast_shadow
    object[:receive_shadow] = receive_shadow
  end

  def set_object_transform(object, position, quaternion, scale)
    @calls << [:set_object_transform, object, position, quaternion, scale]
    object[:position] = position
    object[:quaternion] = quaternion
    object[:scale] = scale
  end

  def update_perspective_camera(camera, fov, aspect, near, far, zoom)
    @calls << [:update_perspective_camera, camera, fov, aspect, near, far, zoom]
    camera[:fov] = fov
    camera[:aspect] = aspect
    camera[:near] = near
    camera[:far] = far
    camera[:zoom] = zoom
  end

  def update_orthographic_camera(camera, left, right, top, bottom, near, far, zoom)
    @calls << [:update_orthographic_camera, camera, left, right, top, bottom, near, far, zoom]
    camera[:left] = left
    camera[:right] = right
    camera[:top] = top
    camera[:bottom] = bottom
    camera[:near] = near
    camera[:far] = far
    camera[:zoom] = zoom
  end

  def update_light(light, color, intensity)
    @calls << [:update_light, light, color, intensity]
    light[:color] = color
    light[:intensity] = intensity
  end

  def update_point_light(light, color, intensity, distance, decay)
    @calls << [:update_point_light, light, color, intensity, distance, decay]
    light[:color] = color
    light[:intensity] = intensity
    light[:distance] = distance
    light[:decay] = decay
  end

  def update_hemisphere_light(light, sky_color, ground_color, intensity)
    @calls << [:update_hemisphere_light, light, sky_color, ground_color, intensity]
    light[:sky_color] = sky_color
    light[:ground_color] = ground_color
    light[:intensity] = intensity
  end

  def update_light_shadow(light, parameters)
    @calls << [:update_light_shadow, light, parameters]
    return unless light[:shadow]

    light[:shadow].merge!(parameters)
  end

  def update_material(material, parameters)
    @calls << [:update_material, material, parameters]
    material[:parameters] = parameters.dup
  end

  def add_child(parent, child)
    @calls << [:add_child, parent, child]
    parent[:children] << child unless parent[:children].include?(child)
    child[:parent] = parent
  end

  def clear_children(parent)
    @calls << [:clear_children, parent]
    parent[:children].each { |child| child.delete(:parent) }
    parent[:children].clear
  end

  def set_scene_background(scene, background)
    @calls << [:set_scene_background, scene, background]
    scene[:background] = background
  end

  def set_scene_environment(scene, environment)
    @calls << [:set_scene_environment, scene, environment]
    scene[:environment] = environment
  end

  def dispose(handle)
    @calls << [:dispose, handle]
  end

  def object_handle_key(object)
    return nil unless object

    object[:uuid] ||= "fake-#{object.object_id}"
  end

  def intersection_distance(intersection)
    intersection[:distance]
  end

  def intersection_point(intersection)
    intersection[:point]
  end

  def intersection_object(intersection)
    intersection[:object]
  end

  def intersection_uv(intersection)
    intersection[:uv]
  end

  def intersection_face_index(intersection)
    intersection[:face_index]
  end

  def intersection_index(intersection)
    intersection[:index]
  end

  def intersection_instance_id(intersection)
    intersection[:instance_id]
  end

  def traverse_object3d(object, callback)
    callback.call(object)
    object.fetch(:children, []).dup.each { |child| traverse_object3d(child, callback) }
    object
  end

  def dispose_object3d_subtree(
    object,
    remove: true,
    dispose_geometries: true,
    dispose_materials: true,
    dispose_textures: false,
    dispose_skeletons: true
  )
    resources = {
      geometries: [],
      materials: [],
      textures: [],
      skeletons: []
    }

    traverse_object3d(object, proc do |node|
      collect_object3d_resources(
        node,
        resources,
        dispose_geometries: dispose_geometries,
        dispose_materials: dispose_materials,
        dispose_textures: dispose_textures,
        dispose_skeletons: dispose_skeletons
      )
    end)

    remove_from_parent(object) if remove

    resources[:geometries].each { |resource| dispose(resource) }
    resources[:materials].each { |resource| dispose(resource) }
    resources[:textures].each { |resource| dispose(resource) }
    resources[:skeletons].each { |resource| dispose(resource) }
    object
  end

  private

  def handle(type, attributes = {})
    { type: type }.merge(attributes)
  end

  def default_shadow
    {
      map_size: [512, 512],
      bias: 0,
      normal_bias: 0,
      radius: 1,
      camera: {}
    }
  end

  def collect_object3d_resources(node, resources, dispose_geometries:, dispose_materials:, dispose_textures:, dispose_skeletons:)
    add_unique(resources[:geometries], node[:geometry]) if dispose_geometries && node[:geometry]
    collect_materials(node[:material], resources, dispose_textures: dispose_textures) if dispose_materials

    if dispose_textures
      add_unique(resources[:textures], node[:background]) if node[:background]
      add_unique(resources[:textures], node[:environment]) if node[:environment]
    end

    add_unique(resources[:skeletons], node[:skeleton]) if dispose_skeletons && node[:skeleton]
  end

  def collect_materials(material, resources, dispose_textures:)
    return unless material

    entries = material.is_a?(Array) ? material : [material]
    entries.each do |entry|
      add_unique(resources[:materials], entry)
      collect_material_textures(entry, resources) if dispose_textures
    end
  end

  def collect_material_textures(material, resources)
    TEXTURE_SLOTS.each do |slot|
      texture = material[slot] || material.dig(:parameters, slot)
      add_unique(resources[:textures], texture) if texture
    end
  end

  def add_unique(resources, resource)
    resources << resource unless resources.include?(resource)
  end

  def remove_from_parent(object)
    parent = object[:parent]
    return unless parent

    parent[:children].delete(object)
    object.delete(:parent)
  end
end
