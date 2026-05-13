import { DefaultRubyVM } from "@ruby/wasm-wasi/browser";
import * as THREE from "three";

const setStatus = globalThis.__threeRbSetStatus || (() => {});
const bootFailed = globalThis.__threeRbBootFailed || ((message) => console.error(message));

try {
  setStatus("Loading ruby.wasm", "loading");
  globalThis.THREE = THREE;
  globalThis.__threeReady = Promise.resolve(THREE);
  globalThis.__threeRbRenderCount = 0;
  globalThis.__threeRbRenderFrameCount = 0;
  globalThis.__threeRbRender = () => {
    globalThis.__threeRbRenderCount += 1;
    const renderer = globalThis.__threeRbCurrentRenderer;
    const scene = globalThis.__threeRbCurrentScene;
    const camera = globalThis.__threeRbCurrentCamera;
    globalThis.requestAnimationFrame(() => {
      globalThis.__threeRbRenderFrameCount += 1;
      renderer.setClearColor(0x0f1419, 1);
      renderer.render(scene, camera);
    });
  };

  const rubyModule = await compileWasm("/node_modules/@ruby/3.4-wasm-wasi/dist/ruby+stdlib.wasm");
  const { vm } = await DefaultRubyVM(rubyModule);
  globalThis.rubyVM = vm;

  setStatus("Starting Ruby VM", "loading");
  await vm.evalAsync(`
    require "js/require_remote/relative_shim"
    JS::RequireRemote.instance.base_url = "/"
    JS::RequireRemote.instance.load("examples/browser/composition/main")
  `);
} catch (error) {
  bootFailed(error && error.message ? error.message : "Ruby boot failed");
  throw error;
}

async function compileWasm(url) {
  const response = fetch(url);
  if (WebAssembly.compileStreaming) {
    try {
      return await WebAssembly.compileStreaming(response);
    } catch (_error) {
      // Fall back when a static server does not provide application/wasm.
    }
  }

  const fallbackResponse = await fetch(url);
  if (!fallbackResponse.ok) {
    throw new Error(`Failed to load ruby.wasm: ${fallbackResponse.status} ${fallbackResponse.statusText}`);
  }
  return WebAssembly.compile(await fallbackResponse.arrayBuffer());
}
