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

    await page.goto(`${server.url}/examples/browser/serialization/`, { waitUntil: "load" });
    await waitForRunning(page, diagnostics);
    await page.waitForTimeout(1_000);

    assertNonBlankCanvas(await sampleCanvas(page));

    const state = await page.evaluate(() => ({
      frame: globalThis.__threeRbSerializationFrame,
      sceneChildren: globalThis.__threeRbScene?.children?.length,
      leftType: globalThis.__threeRbLoadedLeft?.type,
      rightType: globalThis.__threeRbLoadedRight?.type,
      sharedGeometry: globalThis.__threeRbLoadedSharedGeometry,
      sharedMaterial: globalThis.__threeRbLoadedSharedMaterial,
      sharedTexture: globalThis.__threeRbLoadedSharedTexture,
      serialized: JSON.parse(globalThis.__threeRbSerializedJson),
      renderInfo: globalThis.__threeRbRenderer?.info?.render
    }));

    if (state.sceneChildren !== 2 || state.leftType !== "Mesh" || state.rightType !== "Mesh") {
      throw new Error(`loaded scene graph is unexpected: ${JSON.stringify(state)}`);
    }
    if (!state.sharedGeometry || !state.sharedMaterial || !state.sharedTexture) {
      throw new Error(`loaded resources were not shared: ${JSON.stringify(state)}`);
    }
    if (state.serialized.geometries?.length !== 1 || state.serialized.materials?.length !== 1 || state.serialized.textures?.length !== 1) {
      throw new Error(`export did not deduplicate resources: ${JSON.stringify(state.serialized)}`);
    }
    if (!state.renderInfo || state.renderInfo.triangles < 24) {
      throw new Error(`renderer did not draw the loaded meshes: ${JSON.stringify(state)}`);
    }
    if (!state.frame) {
      throw new Error(`serialization example animation did not advance: ${JSON.stringify(state)}`);
    }

    assertNoDiagnostics(diagnostics);

    console.log(`serialization smoke test passed at ${server.url}/examples/browser/serialization/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
