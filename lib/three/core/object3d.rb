# frozen_string_literal: true

require_relative "../math/euler"
require_relative "../math/math_utils"
require_relative "../math/matrix4"
require_relative "../math/quaternion"
require_relative "../math/vector3"
require_relative "../dirty"
require_relative "event_dispatcher"

module Three
  class Object3D < EventDispatcher
    include Dirty

    DEFAULT_UP = Vector3.new(0, 1, 0)
    DEFAULT_MATRIX_AUTO_UPDATE = true
    DEFAULT_MATRIX_WORLD_AUTO_UPDATE = true

    @next_id = 0

    class << self
      attr_accessor :next_id
    end

    attr_reader :id, :uuid, :parent, :children
    attr_reader :position, :rotation, :quaternion, :scale
    attr_reader :matrix, :matrix_world
    attr_reader :name, :type, :up, :visible, :cast_shadow, :receive_shadow
    attr_accessor :matrix_auto_update, :matrix_world_auto_update, :matrix_world_needs_update
    attr_accessor :user_data

    def initialize
      super

      @id = self.class.allocate_id
      @uuid = MathUtils.generate_uuid
      @name = ""
      @type = "Object3D"
      @parent = nil
      @children = []
      @up = DEFAULT_UP.clone

      @position = Vector3.new
      @rotation = Euler.new
      @quaternion = Quaternion.new
      @scale = Vector3.new(1, 1, 1)
      @matrix = Matrix4.new
      @matrix_world = Matrix4.new
      @matrix_auto_update = DEFAULT_MATRIX_AUTO_UPDATE
      @matrix_world_auto_update = DEFAULT_MATRIX_WORLD_AUTO_UPDATE
      @matrix_world_needs_update = false
      @visible = true
      @cast_shadow = false
      @receive_shadow = false
      @user_data = {}

      bind_rotation_and_quaternion
      bind_transform_changes
      mark_dirty!
    end

    def name=(value)
      @name = value
      mark_dirty!(:properties)
    end

    def type=(value)
      @type = value
      mark_dirty!(:properties)
    end

    def up=(value)
      @up = value
      mark_dirty!(:transform)
    end

    def visible=(value)
      @visible = value
      mark_dirty!(:properties)
    end

    def cast_shadow=(value)
      @cast_shadow = value
      mark_dirty!(:properties)
    end

    def receive_shadow=(value)
      @receive_shadow = value
      mark_dirty!(:properties)
    end

    def self.allocate_id
      id = Object3D.next_id
      Object3D.next_id += 1
      id
    end

    def add(*objects)
      objects.each { |object| add_one(object) }
      self
    end

    def remove(*objects)
      objects.each { |object| remove_one(object) }
      self
    end

    def remove_from_parent
      @parent&.remove(self)
      self
    end

    def clear
      remove(*@children.dup)
    end

    def traverse(&block)
      return enum_for(:traverse) unless block

      block.call(self)
      @children.each { |child| child.traverse(&block) }
      self
    end

    def traverse_visible(&block)
      return enum_for(:traverse_visible) unless block
      return self unless @visible

      block.call(self)
      @children.each { |child| child.traverse_visible(&block) }
      self
    end

    def traverse_ancestors(&block)
      return enum_for(:traverse_ancestors) unless block
      return self unless @parent

      block.call(@parent)
      @parent.traverse_ancestors(&block)
      self
    end

    def get_object_by_id(id)
      get_object_by_property(:id, id)
    end

    def get_object_by_name(name)
      get_object_by_property(:name, name)
    end

    def get_object_by_property(property, value)
      return self if public_send(property) == value

      @children.each do |child|
        object = child.get_object_by_property(property, value)
        return object if object
      end

      nil
    end

    def get_objects_by_property(property, value, result = [])
      result << self if public_send(property) == value
      @children.each { |child| child.get_objects_by_property(property, value, result) }
      result
    end

    def update_matrix
      @matrix.compose(@position, @quaternion, @scale)
      @matrix_world_needs_update = true
      self
    end

    def update_matrix_world(force = false)
      update_matrix if @matrix_auto_update

      if @matrix_world_needs_update || force
        if @matrix_world_auto_update
          if @parent
            @matrix_world.multiply_matrices(@parent.matrix_world, @matrix)
          else
            @matrix_world.copy(@matrix)
          end
        end

        @matrix_world_needs_update = false
        force = true
      end

      @children.each { |child| child.update_matrix_world(force) }
      self
    end

    def update_world_matrix(update_parents = false, update_children = false)
      @parent&.update_world_matrix(true, false) if update_parents
      update_matrix if @matrix_auto_update

      if @matrix_world_auto_update
        if @parent
          @matrix_world.multiply_matrices(@parent.matrix_world, @matrix)
        else
          @matrix_world.copy(@matrix)
        end
      end

      @children.each { |child| child.update_world_matrix(false, true) } if update_children
      self
    end

    def get_world_position(target = Vector3.new)
      update_world_matrix(true, false)
      target.set_from_matrix_position(@matrix_world)
    end

    def get_world_quaternion(target = Quaternion.new)
      update_world_matrix(true, false)
      @matrix_world.decompose(Vector3.new, target, Vector3.new)
      target
    end

    def get_world_scale(target = Vector3.new)
      update_world_matrix(true, false)
      @matrix_world.decompose(Vector3.new, Quaternion.new, target)
      target
    end

    def get_world_direction(target = Vector3.new)
      update_world_matrix(true, false)
      elements = @matrix_world.elements
      target.set(elements[8], elements[9], elements[10]).normalize
    end

    def to_h
      {
        uuid: @uuid,
        type: @type,
        name: @name,
        matrix: @matrix.to_a,
        visible: @visible,
        cast_shadow: @cast_shadow,
        receive_shadow: @receive_shadow,
        user_data: @user_data,
        children: @children.map(&:to_h)
      }
    end

    protected

    attr_writer :parent

    private

    def add_one(object)
      raise ArgumentError, "object cannot be added as a child of itself" if object.equal?(self)
      raise TypeError, "object must be a Three::Object3D" unless object.is_a?(Object3D)

      object.remove_from_parent
      object.parent = self
      @children << object
      mark_dirty!(:children)
      object.mark_dirty!(:transform)
      object.dispatch_event(:added)
      dispatch_event(:childadded, object)
    end

    def remove_one(object)
      return unless @children.include?(object)

      @children.delete(object)
      object.parent = nil
      mark_dirty!(:children)
      object.mark_dirty!(:transform)
      object.dispatch_event(:removed)
      dispatch_event(:childremoved, object)
    end

    def bind_rotation_and_quaternion
      @rotation.on_change do
        @quaternion.set_from_euler(@rotation, update: false)
        @matrix_world_needs_update = true
        mark_dirty!(:transform)
      end

      @quaternion.on_change do
        @rotation.set_from_quaternion(@quaternion, @rotation.order, update: false)
        @matrix_world_needs_update = true
        mark_dirty!(:transform)
      end
    end

    def bind_transform_changes
      [@position, @scale].each do |vector|
        vector.on_change do
          @matrix_world_needs_update = true
          mark_dirty!(:transform)
        end
      end
    end
  end
end
