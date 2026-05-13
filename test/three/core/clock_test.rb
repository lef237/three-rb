# frozen_string_literal: true

require "test_helper"

class ThreeClockTest < Minitest::Test
  def test_get_delta_auto_starts_and_accumulates_elapsed_time
    now = 10.0
    clock = Three::Clock.new(time_source: proc { now })

    assert_equal 0, clock.get_delta
    assert clock.running
    assert_equal 10.0, clock.start_time

    now = 10.25
    assert_in_delta 0.25, clock.get_delta, 1e-12
    assert_in_delta 0.25, clock.elapsed_time, 1e-12
  end

  def test_start_resets_elapsed_time
    now = 1.0
    clock = Three::Clock.new(time_source: proc { now })

    clock.start
    now = 2.5
    clock.get_delta
    now = 5.0
    clock.start

    assert_equal 5.0, clock.start_time
    assert_equal 0, clock.elapsed_time
  end

  def test_stop_freezes_elapsed_time_and_disables_auto_start
    now = 1.0
    clock = Three::Clock.new(time_source: proc { now })

    clock.start
    now = 2.0
    clock.stop
    now = 3.0

    assert_equal 1.0, clock.elapsed_time
    refute clock.running
    refute clock.auto_start
    assert_equal 0, clock.get_delta
  end
end
