# frozen_string_literal: true

module Three
  class EventDispatcher
    Event = Struct.new(:type, :target, :data, keyword_init: true)

    def initialize
      @listeners = Hash.new { |hash, key| hash[key] = [] }
    end

    def add_event_listener(type, listener = nil, &block)
      callback = listener || block
      raise ArgumentError, "listener or block is required" unless callback

      listeners = @listeners[type.to_sym]
      listeners << callback unless listeners.include?(callback)
      self
    end

    alias on add_event_listener

    def has_event_listener?(type, listener)
      @listeners[type.to_sym].include?(listener)
    end

    def remove_event_listener(type, listener)
      @listeners[type.to_sym].delete(listener)
      self
    end

    alias off remove_event_listener

    def dispatch_event(event, data = nil)
      event = normalize_event(event, data)
      listeners = @listeners[event.type.to_sym]
      return self if listeners.empty?

      event.target = self
      listeners.dup.each { |listener| listener.call(event) }
      event.target = nil
      self
    end

    private

    def normalize_event(event, data)
      case event
      when Event
        event
      when Hash
        Event.new(type: event.fetch(:type), data: event)
      else
        Event.new(type: event, data: data)
      end
    end
  end
end
