# frozen_string_literal: true

require "test_helper"

class ThreeEventDispatcherTest < Minitest::Test
  def test_dispatches_symbol_events_to_registered_listeners
    dispatcher = Three::EventDispatcher.new
    received = []

    dispatcher.add_event_listener(:change) { |event| received << [event.type, event.target] }
    dispatcher.dispatch_event(:change)

    assert_equal [[:change, dispatcher]], received
  end

  def test_does_not_register_same_listener_twice
    dispatcher = Three::EventDispatcher.new
    calls = 0
    listener = proc { calls += 1 }

    dispatcher.add_event_listener(:change, listener)
    dispatcher.add_event_listener(:change, listener)
    dispatcher.dispatch_event(:change)

    assert_equal 1, calls
  end

  def test_removes_listener
    dispatcher = Three::EventDispatcher.new
    calls = 0
    listener = proc { calls += 1 }

    dispatcher.add_event_listener(:change, listener)
    dispatcher.remove_event_listener(:change, listener)
    dispatcher.dispatch_event(:change)

    assert_equal 0, calls
  end
end
