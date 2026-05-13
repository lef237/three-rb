# Browser glTF Example

This example renders a small glTF asset through ruby.wasm and the JavaScript three.js renderer. It focuses on `GLTFLoader` and adding a loaded external scene to the Ruby-authored scene graph.

## Run

From the repository root:

```sh
ruby -run -e httpd . -p 8000
```

Open:

```text
http://127.0.0.1:8000/examples/browser/gltf/
```

## Smoke Test

```sh
pnpm test:browser:gltf
```
