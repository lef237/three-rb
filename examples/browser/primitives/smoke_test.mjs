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

    await page.goto(`${server.url}/examples/browser/primitives/`, { waitUntil: "load" });
    await waitForRunning(page, diagnostics);
    await page.waitForTimeout(1_000);

    assertNonBlankCanvas(await sampleCanvas(page));

    const state = await page.evaluate(() => ({
      frame: globalThis.__threeRbPrimitivesFrame,
      line: {
        type: globalThis.__threeRbLine?.type,
        materialType: globalThis.__threeRbLine?.material?.type,
        positionCount: globalThis.__threeRbLine?.geometry?.attributes?.position?.count,
        color: globalThis.__threeRbLine?.material?.color?.getHex?.()
      },
      points: {
        type: globalThis.__threeRbPoints?.type,
        materialType: globalThis.__threeRbPoints?.material?.type,
        positionCount: globalThis.__threeRbPoints?.geometry?.attributes?.position?.count,
        color: globalThis.__threeRbPoints?.material?.color?.getHex?.(),
        size: globalThis.__threeRbPoints?.material?.size,
        sizeAttenuation: globalThis.__threeRbPoints?.material?.sizeAttenuation
      },
      renderInfo: globalThis.__threeRbRenderer?.info?.render
    }));

    if (state.line.type !== "Line" || state.line.materialType !== "LineBasicMaterial" || state.line.positionCount !== 5) {
      throw new Error(`line primitive did not materialize correctly: ${JSON.stringify(state)}`);
    }
    if (
      state.points.type !== "Points" ||
      state.points.materialType !== "PointsMaterial" ||
      state.points.positionCount !== 6 ||
      state.points.size !== 12 ||
      state.points.sizeAttenuation !== false
    ) {
      throw new Error(`points primitive did not materialize correctly: ${JSON.stringify(state)}`);
    }
    if (!state.renderInfo || state.renderInfo.calls < 2 || !state.frame) {
      throw new Error(`primitives scene did not render or animate: ${JSON.stringify(state)}`);
    }

    assertNoDiagnostics(diagnostics);

    console.log(`primitives smoke test passed at ${server.url}/examples/browser/primitives/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
