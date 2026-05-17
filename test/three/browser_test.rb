# frozen_string_literal: true

require "test_helper"

class ThreeBrowserTest < Minitest::Test
  FakeEvent = Struct.new(:values, keyword_init: true) do
    def [](key)
      values.fetch(key)
    end
  end

  FakeRect = Struct.new(:values, keyword_init: true) do
    def [](key)
      values.fetch(key)
    end
  end

  class FakeHandle
    attr_reader :calls, :listeners

    def initialize(properties = {}, rect: nil)
      @properties = properties
      @rect = rect || { left: 0, top: 0, width: 1, height: 1 }
      @calls = []
      @listeners = Hash.new { |hash, key| hash[key] = [] }
    end

    def [](key)
      @properties[key]
    end

    def []=(key, value)
      @properties[key] = value
    end

    def call(name, *args)
      @calls << [name, *args]
      case name
      when :addEventListener
        event_name, callback = args
        @listeners[event_name.to_s] << callback
      when :getBoundingClientRect
        FakeRect.new(values: @rect)
      when :requestAnimationFrame
        args.first
      else
        value = @properties[name]
        value.call(*args) if value.respond_to?(:call)
      end
    end

    def dispatch(name, event)
      @listeners[name.to_s].each { |callback| callback.call(event) }
    end
  end

  class FakeDocument
    def initialize(selectors)
      @selectors = selectors
    end

    def call(name, *args)
      raise "unexpected call: #{name}" unless name == :querySelector

      @selectors.fetch(args.first)
    end
  end

  class FakeStorageHandle
    def initialize
      @values = {}
    end

    def [](key)
      key == :length ? @values.length : nil
    end

    def call(name, *args)
      case name
      when :setItem
        @values[args.fetch(0)] = args.fetch(1)
      when :getItem
        @values[args.fetch(0)]
      when :removeItem
        @values.delete(args.fetch(0))
      when :clear
        @values.clear
      when :key
        @values.keys[args.fetch(0)]
      else
        raise "unexpected storage call: #{name}"
      end
    end
  end

  class FakeGlobal
    def initialize(values = {})
      @values = values
    end

    def [](key)
      @values[key]
    end

    def []=(key, value)
      @values[key] = value
    end

    def call(name, *args)
      value = @values[name]
      value.call(*args) if value.respond_to?(:call)
    end
  end

  class FakeRenderer
    attr_reader :animation_callback

    def animation_loop(&block)
      @animation_callback = block
      self
    end
  end

  def test_key_and_pointer_helpers_register_browser_events
    with_browser_app do |app, window:, viewport:, **|
      keys = []
      app.on_key(key: "Escape") { |event| keys << event[:key] }

      window.dispatch("keydown", FakeEvent.new(values: { key: "Enter" }))
      window.dispatch("keydown", FakeEvent.new(values: { key: "Escape" }))

      captured = nil
      app.on_pointer("click", target: "#viewport") do |event, x, y|
        captured = [event, x, y]
      end
      event = FakeEvent.new(values: { clientX: 110, clientY: 20 })
      viewport.dispatch("click", event)

      assert_equal ["Escape"], keys
      assert_same event, captured[0]
      assert_in_delta 1.0, captured[1]
      assert_in_delta 1.0, captured[2]
      assert_equal [1.0, 1.0], app.pointer_ndc(event, target: "#viewport")
    end
  end

  def test_storage_helper_wraps_local_session_and_custom_storage
    with_browser_app do |app, local_storage:, session_storage:, **|
      local = app.storage
      local.set(:mode, "ruby")

      assert_equal "ruby", local.get(:mode)
      assert_equal 1, local.length
      assert_equal "mode", local.key(0)

      local.delete(:mode)
      assert_nil local.get(:mode)

      app.storage(:session).set(:frame, 12)
      assert_equal 12, session_storage.call(:getItem, "frame")

      custom = FakeStorageHandle.new
      assert_same custom, app.storage(custom).handle
      assert_same local_storage, local.handle
    end
  end

  def test_animation_loop_delegates_to_renderer_or_request_animation_frame
    with_browser_app do |app, window:, **|
      renderer = FakeRenderer.new
      result = app.animation_loop(renderer) { :frame }

      assert_same renderer, result
      assert_equal :frame, renderer.animation_callback.call

      frames = []
      callback = app.animation_loop { |time| frames << time }
      callback.call(24.0)

      assert_equal [24.0], frames
      assert_equal :requestAnimationFrame, window.calls[-2].first
      assert_equal :requestAnimationFrame, window.calls[-1].first
    end
  end

  private

  def with_browser_app
    viewport = FakeHandle.new(
      { clientWidth: 100, clientHeight: 50 },
      rect: { left: 10, top: 20, width: 100, height: 50 }
    )
    window = FakeHandle.new
    local_storage = FakeStorageHandle.new
    session_storage = FakeStorageHandle.new
    global = FakeGlobal.new(
      document: nil,
      window: window,
      localStorage: local_storage,
      sessionStorage: session_storage
    )
    document = FakeDocument.new("#viewport" => viewport)
    global[:document] = document

    with_browser_environment(global: global, document: document, window: window) do
      app = Three::Browser::Application.new(status_selector: nil, status_dot_selector: nil)
      yield app,
            global: global,
            document: document,
            window: window,
            viewport: viewport,
            local_storage: local_storage,
            session_storage: session_storage
    end
  end

  def with_browser_environment(global:, document:, window:)
    originals = {}
    %i[ready! global document window].each do |name|
      originals[name] = Three::Browser.method(name)
    end

    with_silent_method_redefinition do
      Three::Browser.define_singleton_method(:ready!) { self }
      Three::Browser.define_singleton_method(:global) { global }
      Three::Browser.define_singleton_method(:document) { document }
      Three::Browser.define_singleton_method(:window) { window }
    end

    yield
  ensure
    with_silent_method_redefinition do
      originals.each do |name, original|
        Three::Browser.define_singleton_method(name) do |*args, **kwargs, &block|
          if kwargs.empty?
            original.call(*args, &block)
          else
            original.call(*args, **kwargs, &block)
          end
        end
      end
    end
  end

  def with_silent_method_redefinition
    verbose = $VERBOSE
    $VERBOSE = nil
    yield
  ensure
    $VERBOSE = verbose
  end
end
