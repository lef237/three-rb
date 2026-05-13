# frozen_string_literal: true

module Three
  class Clock
    attr_accessor :auto_start
    attr_reader :start_time, :old_time, :elapsed_time, :running

    def initialize(auto_start: true, time_source: nil)
      @auto_start = auto_start
      @time_source = time_source || proc { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
      @start_time = 0
      @old_time = 0
      @elapsed_time = 0
      @running = false
    end

    def start
      @start_time = now
      @old_time = @start_time
      @elapsed_time = 0
      @running = true
      self
    end

    def stop
      get_elapsed_time
      @running = false
      @auto_start = false
      self
    end

    def get_elapsed_time
      get_delta
      @elapsed_time
    end

    def get_delta
      if @auto_start && !@running
        start
        return 0
      end

      return 0 unless @running

      current_time = now
      diff = current_time - @old_time
      @old_time = current_time
      @elapsed_time += diff
      diff
    end

    private

    def now
      @time_source.call.to_f
    end
  end
end
