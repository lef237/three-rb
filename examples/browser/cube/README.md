# Browser Cube Example

This example renders a Ruby-authored cube through ruby.wasm and the JavaScript three.js renderer.

Serve the repository root over HTTP:

```sh
ruby -run -e httpd . -p 8000
```

Then open:

```text
http://localhost:8000/examples/browser/cube/
```

The page uses these browser dependencies:

- `@ruby/3.4-wasm-wasi@2.9.4`
- `three@0.184.0`

The repository root must be served, not only this directory, because `main.rb` loads the library source from `lib/`.
