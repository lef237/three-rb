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

    def mark_dirty!(field = :all)
      dirty_fields[field] = true
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
  end
end
