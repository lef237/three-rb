# three-rb Ruby Example

This browser example is the first visual sample for three-rb. It builds a faceted red gemstone in Ruby with `BufferGeometry`, renders it with `MeshPhysicalMaterial`, and adds an extruded `three-rb` title through the three.js `TextGeometry` addon.

Run it from the repository root:

```sh
pnpm install
ruby -run -e httpd . -p 8000
```

Then open:

```text
http://localhost:8000/examples/browser/ruby/
```

Run its smoke test:

```sh
pnpm test:browser:ruby
```
