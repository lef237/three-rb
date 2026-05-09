import { DefaultRubyVM } from "@ruby/wasm-wasi/browser";
import * as THREE from "three";
import { GLTFLoader } from "three/addons/loaders/GLTFLoader.js";
import { DRACOLoader } from "three/addons/loaders/DRACOLoader.js";
import { HDRLoader } from "three/addons/loaders/HDRLoader.js";
import { FontLoader } from "three/addons/loaders/FontLoader.js";
import { TextGeometry } from "three/addons/geometries/TextGeometry.js";
import { OrbitControls } from "three/addons/controls/OrbitControls.js";
import { EffectComposer } from "three/addons/postprocessing/EffectComposer.js";
import { RenderPass } from "three/addons/postprocessing/RenderPass.js";
import { UnrealBloomPass } from "three/addons/postprocessing/UnrealBloomPass.js";
import { DotScreenPass } from "three/addons/postprocessing/DotScreenPass.js";
import { OutputPass } from "three/addons/postprocessing/OutputPass.js";
import { rubyWasmUrl } from "./config.mjs";

export async function bootRubyExample({ main, clearColor }) {
  const setStatus = globalThis.__threeRbSetStatus || (() => {});
  const bootFailed = globalThis.__threeRbBootFailed || ((message) => console.error(message));

  try {
    setStatus("Preparing browser runtime", "loading", 4);
    globalThis.THREE = THREE;
    globalThis.THREE_GLTF_LOADER = GLTFLoader;
    globalThis.THREE_DRACO_LOADER = DRACOLoader;
    globalThis.THREE_RGBE_LOADER = HDRLoader;
    globalThis.THREE_FONT_LOADER = FontLoader;
    globalThis.THREE_TEXT_GEOMETRY = TextGeometry;
    globalThis.THREE_ORBIT_CONTROLS = OrbitControls;
    globalThis.THREE_EFFECT_COMPOSER = EffectComposer;
    globalThis.THREE_RENDER_PASS = RenderPass;
    globalThis.THREE_UNREAL_BLOOM_PASS = UnrealBloomPass;
    globalThis.THREE_DOT_SCREEN_PASS = DotScreenPass;
    globalThis.THREE_OUTPUT_PASS = OutputPass;
    globalThis.__threeReady = Promise.resolve(THREE);
    globalThis.__threeRbRenderCount = 0;
    globalThis.__threeRbRenderFrameCount = 0;
    globalThis.__threeRbRender = () => {
      globalThis.__threeRbRenderCount += 1;
      const renderer = globalThis.__threeRbCurrentRenderer;
      const scene = globalThis.__threeRbCurrentScene;
      const camera = globalThis.__threeRbCurrentCamera;
      globalThis.__threeRbRenderFrameCount += 1;
      renderer.setClearColor(clearColor, 1);
      renderer.render(scene, camera);
    };
    globalThis.__threeRbRenderComposer = () => {
      globalThis.__threeRbRenderCount += 1;
      const composer = globalThis.__threeRbCurrentComposer;
      globalThis.__threeRbRenderFrameCount += 1;
      composer.render();
    };

    const rubyModule = await compileWasm(rubyWasmUrl, (percent) => {
      setStatus(`Loading ruby.wasm ${percent}%`, "loading", percent);
    });
    setStatus("Compiling ruby.wasm", "loading", 82);
    const { vm } = await DefaultRubyVM(rubyModule);
    globalThis.rubyVM = vm;

    setStatus("Starting Ruby VM", "loading", 88);
    await withNoStoreRubySourceFetch(async () => {
      await vm.evalAsync(`
        require "js/require_remote/relative_shim"
        JS::RequireRemote.instance.base_url = "/"
        JS::RequireRemote.instance.load(${JSON.stringify(main)})
      `);
    });
  } catch (error) {
    bootFailed(error && error.message ? error.message : "Ruby boot failed");
    throw error;
  }
}

async function withNoStoreRubySourceFetch(callback) {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = (input, init = {}) => {
    if (!shouldBypassCache(input)) return originalFetch(input, init);

    return originalFetch(input, { ...init, cache: "no-store" });
  };

  try {
    return await callback();
  } finally {
    globalThis.fetch = originalFetch;
  }
}

function shouldBypassCache(input) {
  const rawUrl = typeof input === "string" ? input : input?.url;
  if (!rawUrl) return false;

  const { pathname } = new URL(rawUrl, globalThis.location?.href || "http://localhost/");
  if (pathname.startsWith("/lib/")) return true;
  if (!pathname.startsWith("/examples/browser/")) return false;

  return !pathname.includes("/assets/");
}

async function compileWasm(url, onProgress = () => {}) {
  if (WebAssembly.compileStreaming) {
    try {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Failed to load ruby.wasm: ${response.status} ${response.statusText}`);
      }

      return await WebAssembly.compileStreaming(trackDownload(response, onProgress));
    } catch (_error) {
      // Fall back when a static server does not provide application/wasm.
    }
  }

  const fallbackResponse = await fetch(url);
  if (!fallbackResponse.ok) {
    throw new Error(`Failed to load ruby.wasm: ${fallbackResponse.status} ${fallbackResponse.statusText}`);
  }
  return WebAssembly.compile(await trackDownload(fallbackResponse, onProgress).arrayBuffer());
}

function trackDownload(response, onProgress) {
  const total = Number(response.headers.get("content-length"));
  if (!response.body || !Number.isFinite(total) || total <= 0) return response;

  let loaded = 0;
  const stream = new ReadableStream({
    async start(controller) {
      const reader = response.body.getReader();
      try {
        while (true) {
          const { done, value } = await reader.read();
          if (done) break;

          loaded += value.byteLength;
          onProgress(Math.min(80, Math.round((loaded / total) * 80)));
          controller.enqueue(value);
        }
        controller.close();
      } catch (error) {
        controller.error(error);
      }
    }
  });

  return new Response(stream, {
    headers: response.headers,
    status: response.status,
    statusText: response.statusText
  });
}
