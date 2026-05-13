# Browser glTF Example

This example renders a small animated glTF asset through ruby.wasm and the JavaScript three.js renderer. It focuses on `GLTFLoader`, adding a loaded external scene to the Ruby-authored scene graph, playing loaded clips through `AnimationMixer`, and disposing the loaded subtree.

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
