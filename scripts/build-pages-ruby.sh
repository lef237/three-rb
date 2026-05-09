#!/bin/sh
set -eu

rm -rf dist

mkdir -p dist/examples/browser
mkdir -p dist/node_modules/@ruby
mkdir -p dist/node_modules/@bjorn3
mkdir -p dist/node_modules

cp -R examples/browser/ruby dist/examples/browser/ruby
cp -R examples/browser/shared dist/examples/browser/shared
cp -R lib dist/lib

cp -RL node_modules/@ruby/wasm-wasi dist/node_modules/@ruby/wasm-wasi
cp -RL node_modules/@bjorn3/browser_wasi_shim dist/node_modules/@bjorn3/browser_wasi_shim
cp -RL node_modules/three dist/node_modules/three

node -e 'const fs = require("fs"); const url = process.env.RUBY_WASM_URL || "https://cdn.jsdelivr.net/npm/@ruby/3.4-wasm-wasi@2.9.4-2026-05-11-a/dist/ruby+stdlib.wasm"; fs.writeFileSync("dist/examples/browser/shared/config.mjs", `export const rubyWasmUrl = ${JSON.stringify(url)};\n`);'
