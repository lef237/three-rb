# three.rb postprocessing browser example

This example renders a Ruby-authored scene through ruby.wasm, the JavaScript three.js renderer, and an explicit postprocessing pipeline. It focuses on `Three::Postprocessing::EffectComposer`, `RenderPass`, `UnrealBloomPass`, `OutputPass`, composer sizing, pass property updates, and rendering through `composer.render(scene, camera)`.

## Run

From the repository root:

```sh
pnpm install
ruby -run -e httpd . -p 8000
```

Open:

```text
http://localhost:8000/examples/browser/postprocessing/
```

## Smoke Test

```sh
pnpm test:browser:postprocessing
```

The smoke test serves the repository root, waits for the Ruby scene to reach `Running`, samples the WebGL canvas for nonblank pixels, verifies that the composer owns a render pass and bloom pass, checks bloom pass settings, and confirms animation frames are rendered through the composer path.
