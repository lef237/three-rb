# Browser Cubemap Example

This example renders a Ruby-authored scene through ruby.wasm and the JavaScript three.js renderer. It focuses on `CubeTextureLoader`, `CubeTexture`, and scene `background`/`environment` synchronization.

## Run

From the repository root:

```sh
ruby -run -e httpd . -p 8000
```

Open:

```text
http://127.0.0.1:8000/examples/browser/cubemap/
```

## Smoke Test

```sh
pnpm test:browser:cubemap
```
