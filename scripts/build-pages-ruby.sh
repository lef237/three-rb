#!/bin/sh
set -eu

rm -rf dist

mkdir -p dist/examples/browser
mkdir -p dist/vendor/@ruby
mkdir -p dist/vendor/@bjorn3
mkdir -p dist/vendor

cp -R examples/browser/ruby dist/examples/browser/ruby
cp -R examples/browser/shared dist/examples/browser/shared
cp -R lib dist/lib

cp -RL node_modules/@ruby/wasm-wasi dist/vendor/@ruby/wasm-wasi
cp -RL node_modules/@bjorn3/browser_wasi_shim dist/vendor/@bjorn3/browser_wasi_shim
cp -RL node_modules/three dist/vendor/three

node -e 'const fs = require("fs"); const url = process.env.RUBY_WASM_URL || "https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@2.9.4-2026-07-17-a/dist/ruby+stdlib.wasm"; fs.writeFileSync("dist/examples/browser/shared/config.mjs", `export const rubyWasmUrl = ${JSON.stringify(url)};\n`);'
node -e 'const fs = require("fs"); for (const path of ["dist/examples/browser/ruby/index.html", "dist/examples/browser/ruby/main.rb"]) { const text = fs.readFileSync(path, "utf8"); fs.writeFileSync(path, text.replaceAll("/node_modules/", "/vendor/")); }'
node -e 'const fs = require("fs"); const html = fs.readFileSync("dist/examples/browser/ruby/index.html", "utf8"); fs.writeFileSync("dist/index.html", html.replaceAll("\"./boot.mjs\"", "\"/boot.mjs\"")); fs.writeFileSync("dist/boot.mjs", `import { bootRubyExample } from "/examples/browser/shared/boot.mjs";\n\nawait bootRubyExample({\n  main: "examples/browser/ruby/main",\n  clearColor: 0xf8fbff\n});\n`);'
