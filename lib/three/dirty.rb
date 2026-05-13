# frozen_string_literal: true

module Three
  module Dirty
    def dirty?
      !dirty_fields.empty?
    end

    def dirty_fields
      @dirty_fields ||= {}
    end

    def dirty_field?(field)
      dirty_fields.key?(:all) || dirty_fields.key?(field)
    end

    def dirty_dependents
      @dirty_dependents ||= []
    end

    def add_dirty_dependent(dependent)
      dirty_dependents << dependent unless dirty_dependents.include?(dependent)
      self
    end

    def remove_dirty_dependent(dependent)
      dirty_dependents.delete(dependent)
      self
    end

    def mark_dirty!(field = :all)
      dirty_fields[field] = true
      notify_dirty_dependents(field)
      self
    end

    def mark_clean!(*fields)
      if fields.empty? || fields.include?(:all)
        dirty_fields.clear
      else
        fields.each { |field| dirty_fields.delete(field) }
      end
      self
    end

    private

    def notify_dirty_dependents(field)
      dirty_dependents.dup.each do |dependent|
        if dependent.respond_to?(:dirty_dependency_changed)
          dependent.dirty_dependency_changed(self, field)
        elsif dependent.respond_to?(:mark_dirty!)
          dependent.mark_dirty!(:dependency)
        end
      end
    end
  end
end
