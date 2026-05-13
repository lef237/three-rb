# Browser glTF Example

This example renders small glTF assets through ruby.wasm and the JavaScript three.js renderer. It focuses on `GLTFLoader`, optional `DRACOLoader` decoder configuration for compressed geometry, adding loaded external scenes to the Ruby-authored scene graph, playing loaded clips through `AnimationMixer`, and disposing loaded subtrees.

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
