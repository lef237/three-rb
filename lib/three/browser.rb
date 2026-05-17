# frozen_string_literal: true

module Three
  module Browser
    class Error < RuntimeError; end

    class Element
      attr_reader :handle

      def initialize(handle)
        @handle = handle
      end

      def self.wrap(value)
        value.is_a?(self) ? value : new(value)
      end

      def client_width
        [@handle[:clientWidth].to_i, 1].max
      end

      def client_height
        [@handle[:clientHeight].to_i, 1].max
      end

      def size
        [client_width, client_height]
      end

      def add_event_listener(name, &block)
        @handle.call(:addEventListener, name.to_s, block)
        self
      end

      alias on add_event_listener

      def bounding_client_rect
        rect = @handle.call(:getBoundingClientRect)
        {
          left: rect[:left].to_f,
          top: rect[:top].to_f,
          width: rect[:width].to_f,
          height: rect[:height].to_f
        }
      end

      def pointer_ndc(event)
        rect = bounding_client_rect
        x = ((event[:clientX].to_f - rect[:left]) / rect[:width]) * 2 - 1
        y = -(((event[:clientY].to_f - rect[:top]) / rect[:height]) * 2 - 1)
        [x, y]
      end
    end

    class Application
      attr_reader :document, :window

      def initialize(starting: nil, status_selector: "#status", status_dot_selector: "#status-dot")
        Browser.ready!
        @document = Browser.document
        @window = Browser.window
        @status = status_selector ? query(status_selector) : nil
        @status_dot = status_dot_selector ? query(status_dot_selector) : nil
        status(starting, state: "loading") if starting
      end

      def query(selector)
        Element.new(@document.call(:querySelector, selector))
      end

      def element(handle)
        Element.wrap(handle)
      end

      def status(message, state: nil)
        setter = Browser.global[:__threeRbSetStatus]
        if js_function?(setter)
          Browser.global.call(:__threeRbSetStatus, message, state)
        else
          @status.handle[:textContent] = message if @status
          @status_dot.handle[:dataset][:state] = state if @status_dot && state
        end
        self
      end

      def running!
        status("Running", state: "running")
      end

      def boot_failed(message)
        failure = Browser.global[:__threeRbBootFailed]
        if js_function?(failure)
          Browser.global.call(:__threeRbBootFailed, message)
        else
          status(message, state: "error")
        end
      end

      def on_resize(viewport: "#viewport", &block)
        viewport_element = viewport.is_a?(Element) ? viewport : query(viewport)
        callback = proc do
          width, height = viewport_element.size
          block.call(width, height, width.to_f / height)
        end

        callback.call
        @window.call(:addEventListener, "resize", callback)
        callback
      end

      def resize_renderer(renderer, camera, viewport: "#viewport")
        on_resize(viewport: viewport) do |width, height, aspect|
          if block_given?
            yield(width, height, aspect)
          elsif camera.respond_to?(:aspect=)
            camera.aspect = aspect
            camera.update_projection_matrix if camera.respond_to?(:update_projection_matrix)
          end
          renderer.set_size(width, height)
        end
      end

      def expose(values, renderer: nil, prefix: "__threeRb")
        values.each do |name, value|
          set(name, value, renderer: renderer, prefix: prefix)
        end
        self
      end

      def set(name, value, renderer: nil, prefix: "__threeRb")
        Browser.global[global_name(name, prefix)] = exposed_value(value, renderer)
        self
      end

      def get(name, prefix: "__threeRb")
        Browser.global[global_name(name, prefix)]
      end

      def increment(name, by: 1, prefix: "__threeRb")
        value = get(name, prefix: prefix).to_i + by
        set(name, value, prefix: prefix)
        value
      end

      private

      def js_function?(value)
        value.respond_to?(:typeof) && value.typeof == "function"
      end

      def camelize(value)
        value.to_s.split("_").map(&:capitalize).join
      end

      def global_name(name, prefix)
        :"#{prefix}#{camelize(name)}"
      end

      def exposed_value(value, renderer)
        if value.is_a?(Array)
          js_array(value, renderer)
        elsif renderer && materializable?(value)
          renderer.backend.materialize(value)
        elsif value.respond_to?(:handle)
          value.handle
        else
          value
        end
      end

      def js_array(values, renderer)
        array = Browser.global[:Array].new
        values.each { |value| array.call(:push, exposed_value(value, renderer)) }
        array
      end

      def materializable?(value)
        value.respond_to?(:uuid) || value.respond_to?(:source) || value.respond_to?(:sources)
      end
    end

    class << self
      def run(**options)
        app = nil
        begin
          install_runtime_extensions
          app = Application.new(**options)
          result = yield app
          app.running!
          result
        rescue StandardError => error
          app ? app.boot_failed(error.message) : notify_boot_failed(error.message)
          raise
        end
      end

      def ready!
        ready = global[:__threeReady]
        ready.await if ready.respond_to?(:await)
        self
      end

      def document
        global[:document]
      end

      def window
        global[:window]
      end

      def global
        require "js"
        JS.global
      rescue LoadError
        raise Error, "Three::Browser requires ruby.wasm's js gem"
      end

      private

      def install_runtime_extensions
        install_renderer_extensions
        install_backend_extensions
        install_adapter_extensions
      end

      def install_renderer_extensions
        renderer = Three::Renderers::ThreeJSRenderer
        unless renderer.method_defined?(:on_dispose)
          renderer.class_eval do
            def on_dispose(object, &block)
              @backend.add_event_listener(object, :dispose, block)
              self
            end
          end
        end

        return if renderer.method_defined?(:cached?)

        renderer.class_eval do
          def cached?(object)
            @backend.cached?(object)
          end
        end
      end

      def install_backend_extensions
        backend = Three::Backends::ThreeJS
        unless backend.method_defined?(:add_event_listener)
          backend.class_eval do
            def add_event_listener(object, type, callback)
              raise ArgumentError, "callback is required" unless callback

              @adapter.add_event_listener(materialize(object), type, callback)
            end
          end
        end

        return if backend.method_defined?(:cached?)

        backend.class_eval do
          def cached?(object)
            key = cache_key(object)
            key ? @handles.key?(key) : false
          end
        end
      end

      def install_adapter_extensions
        adapter = Three::Backends::ThreeJS::RubyWasmAdapter
        return if adapter.method_defined?(:add_event_listener)

        adapter.class_eval do
          def add_event_listener(handle, type, callback)
            handle.call(:addEventListener, type.to_s, callback)
          end
        end
      end

      def notify_boot_failed(message)
        failure = global[:__threeRbBootFailed]
        global.call(:__threeRbBootFailed, message) if failure.respond_to?(:typeof) && failure.typeof == "function"
      rescue Error
        nil
      end
    end
  end
end
