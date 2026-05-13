# frozen_string_literal: true

class FakeThreeJSAdapter
  attr_reader :calls

  def initialize
    @calls = []
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

  def set_animation_loop(renderer, callback)
    @calls << [:set_animation_loop, renderer, callback]
  end

  def render(renderer, scene, camera)
    @calls << [:render, renderer, scene, camera]
  end

  def new_orbit_controls(camera, dom_element)
    handle(:orbit_controls, camera: camera, dom_element: dom_element, target: [0, 0, 0])
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
    handle(:directional_light, color: color, intensity: intensity, children: [])
  end

  def new_point_light(color, intensity, distance, decay)
    handle(:point_light, color: color, intensity: intensity, distance: distance, decay: decay, children: [])
  end

  def new_hemisphere_light(sky_color, ground_color, intensity)
    handle(:hemisphere_light, sky_color: sky_color, ground_color: ground_color, intensity: intensity, children: [])
  end

  def new_mesh(geometry, material)
    handle(:mesh, geometry: geometry, material: material, children: [])
  end

  def set_mesh_geometry(mesh, geometry)
    @calls << [:set_mesh_geometry, mesh, geometry]
    mesh[:geometry] = geometry
  end

  def set_mesh_material(mesh, material)
    @calls << [:set_mesh_material, mesh, material]
    mesh[:material] = material
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

  def new_mesh_lambert_material(parameters)
    handle(:mesh_lambert_material, parameters: parameters.dup)
  end

  def new_mesh_normal_material(parameters)
    handle(:mesh_normal_material, parameters: parameters.dup)
  end

  def new_mesh_standard_material(parameters)
    handle(:mesh_standard_material, parameters: parameters.dup)
  end

  def set_object_name(object, name)
    @calls << [:set_object_name, object, name]
    object[:name] = name
  end

  def set_object_visible(object, visible)
    @calls << [:set_object_visible, object, visible]
    object[:visible] = visible
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

  def update_material(material, parameters)
    @calls << [:update_material, material, parameters]
    material[:parameters] = parameters.dup
  end

  def add_child(parent, child)
    @calls << [:add_child, parent, child]
    parent[:children] << child unless parent[:children].include?(child)
  end

  def clear_children(parent)
    @calls << [:clear_children, parent]
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

  private

  def handle(type, attributes = {})
    { type: type }.merge(attributes)
  end
end
