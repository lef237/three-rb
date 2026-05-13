import {
  assertNoDiagnostics,
  assertNonBlankCanvas,
  createDiagnostics,
  createSmokePage,
  loadPlaywright,
  sampleCanvas,
  startServer,
  waitForRunning
} from "../shared/smoke_test_helpers.mjs";

async function main() {
  const { chromium } = await loadPlaywright();
  const server = await startServer();
  const browser = await chromium.launch({ headless: process.env.HEADLESS !== "0" });
  const diagnostics = createDiagnostics();

  try {
    const page = await createSmokePage(browser, diagnostics);

    await page.goto(`${server.url}/examples/browser/postprocessing/`, { waitUntil: "load" });
    await waitForRunning(page, diagnostics);
    await page.waitForTimeout(1_000);

    assertNonBlankCanvas(await sampleCanvas(page));

    const state = await page.evaluate(() => ({
      frame: globalThis.__threeRbPostFrame,
      renderCount: globalThis.__threeRbRenderCount,
      renderFrameCount: globalThis.__threeRbRenderFrameCount,
      renderInfo: globalThis.__threeRbRenderer?.info?.render,
      composerPasses: globalThis.__threeRbPostComposer?.passes?.map((pass) => pass?.constructor?.name),
      composerWidth: globalThis.__threeRbPostComposer?.renderTarget1?.width,
      composerHeight: globalThis.__threeRbPostComposer?.renderTarget1?.height,
      renderPassEnabled: globalThis.__threeRbPostRenderPass?.enabled,
      renderPassSceneSame: globalThis.__threeRbPostRenderPass?.scene === globalThis.__threeRbScene,
      renderPassCameraSame: globalThis.__threeRbPostRenderPass?.camera === globalThis.__threeRbCamera,
      bloomPassEnabled: globalThis.__threeRbPostBloomPass?.enabled,
      bloomStrength: globalThis.__threeRbPostBloomPass?.strength,
      bloomRadius: globalThis.__threeRbPostBloomPass?.radius,
      bloomThreshold: globalThis.__threeRbPostBloomPass?.threshold,
      coreType: globalThis.__threeRbPostCore?.type,
      coreGeometryType: globalThis.__threeRbPostCore?.geometry?.type,
      ringType: globalThis.__threeRbPostRing?.type,
      leftAccentType: globalThis.__threeRbPostLeftAccent?.type,
      rightAccentType: globalThis.__threeRbPostRightAccent?.type
    }));

    if (!Array.isArray(state.composerPasses) || state.composerPasses.length !== 2) {
      throw new Error(`expected two postprocessing passes: ${JSON.stringify(state)}`);
    }
    if (state.composerPasses[0] !== "RenderPass" || state.composerPasses[1] !== "UnrealBloomPass") {
      throw new Error(`expected RenderPass then UnrealBloomPass: ${JSON.stringify(state)}`);
    }
    if (state.composerWidth <= 0 || state.composerHeight <= 0) {
      throw new Error(`expected composer render targets to be sized: ${JSON.stringify(state)}`);
    }
    if (state.renderPassEnabled !== true || state.renderPassSceneSame !== true || state.renderPassCameraSame !== true) {
      throw new Error(`expected render pass to target the Ruby-authored scene and camera: ${JSON.stringify(state)}`);
    }
    if (
      state.bloomPassEnabled !== true ||
      state.bloomStrength < 0.9 ||
      Math.abs(state.bloomRadius - 0.42) > 1e-12 ||
      Math.abs(state.bloomThreshold - 0.22) > 1e-12
    ) {
      throw new Error(`expected configured bloom pass values: ${JSON.stringify(state)}`);
    }
    if (
      state.coreType !== "Mesh" ||
      state.coreGeometryType !== "SphereGeometry" ||
      state.ringType !== "Mesh" ||
      state.leftAccentType !== "Mesh" ||
      state.rightAccentType !== "Mesh"
    ) {
      throw new Error(`postprocessing scene objects did not materialize: ${JSON.stringify(state)}`);
    }
    if (!state.renderInfo || state.renderInfo.calls < 1 || !state.frame || state.renderCount < 2 || state.renderFrameCount < 2) {
      throw new Error(`postprocessing scene did not render or animate through composer: ${JSON.stringify(state)}`);
    }

    assertNoDiagnostics(diagnostics);

    console.log(`postprocessing smoke test passed at ${server.url}/examples/browser/postprocessing/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
