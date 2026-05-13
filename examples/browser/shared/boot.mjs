import { DefaultRubyVM } from "@ruby/wasm-wasi/browser";
import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { DRACOLoader } from "three/addons/loaders/DRACOLoader.js";
import { HDRLoader } from "three/addons/loaders/HDRLoader.js";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";

export async function bootRubyExample({ main, clearColor }) {
  const setStatus = globalThis.__threeRbSetStatus || (() => {});
  const bootFailed = globalThis.__threeRbBootFailed || ((message) => console.error(message));

  try {
    setStatus("Loading ruby.wasm", "loading");
    globalThis.THREE = THREE;
    globalThis.THREE_GLTF_LOADER = GLTFLoader;
    globalThis.THREE_DRACO_LOADER = DRACOLoader;
    globalThis.THREE_RGBE_LOADER = HDRLoader;
    globalThis.THREE_ORBIT_CONTROLS = OrbitControls;
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
        renderer.setClearColor(clearColor, 1);
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
      JS::RequireRemote.instance.load(${JSON.stringify(main)})
    `);
  } catch (error) {
    bootFailed(error && error.message ? error.message : "Ruby boot failed");
    throw error;
  }
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
