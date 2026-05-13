# frozen_string_literal: true

class FakeThreeJSAdapter
  attr_reader :calls

  def initialize
    @calls = []
  end

  def new_webgl_renderer(options = {})
    handle(:renderer, options: options)
  end

  def set_renderer_size(renderer, width, height)
    @calls << [:set_renderer_size, renderer, width, height]
  end

  def set_animation_loop(renderer, callback)
    @calls << [:set_animation_loop, renderer, callback]
  end

  def render(renderer, scene, camera)
    @calls << [:render, renderer, scene, camera]
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

  def new_mesh(geometry, material)
    handle(:mesh, geometry: geometry, material: material, children: [])
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

  def new_buffer_geometry
    handle(:buffer_geometry, attributes: {}, groups: [])
  end

  def new_buffer_attribute(component_type, array, item_size, normalized)
    handle(:buffer_attribute, component_type: component_type, array: array.dup, item_size: item_size, normalized: normalized)
  end

  def set_geometry_index(geometry, attribute)
    geometry[:index] = attribute
  end

  def set_geometry_attribute(geometry, name, attribute)
    geometry[:attributes][name] = attribute
  end

  def add_geometry_group(geometry, start, count, material_index)
    geometry[:groups] << { start: start, count: count, material_index: material_index }
  end

  def set_geometry_draw_range(geometry, start, count)
    geometry[:draw_range] = { start: start, count: count }
  end

  def new_mesh_basic_material(parameters)
    handle(:mesh_basic_material, parameters: parameters.dup)
  end

  def set_object_name(object, name)
    object[:name] = name
  end

  def set_object_visible(object, visible)
    object[:visible] = visible
  end

  def set_object_transform(object, position, quaternion, scale)
    object[:position] = position
    object[:quaternion] = quaternion
    object[:scale] = scale
  end

  def update_perspective_camera(camera, fov, aspect, near, far, zoom)
    camera[:fov] = fov
    camera[:aspect] = aspect
    camera[:near] = near
    camera[:far] = far
    camera[:zoom] = zoom
  end

  def update_material(material, parameters)
    material[:parameters] = parameters.dup
  end

  def add_child(parent, child)
    parent[:children] << child unless parent[:children].include?(child)
  end

  def dispose(handle)
    @calls << [:dispose, handle]
  end

  private

  def handle(type, attributes = {})
    { type: type }.merge(attributes)
  end
end
