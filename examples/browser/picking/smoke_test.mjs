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

    await page.goto(`${server.url}/examples/browser/picking/`, { waitUntil: "load" });
    await waitForRunning(page, diagnostics);
    await page.waitForTimeout(1_000);

    assertNonBlankCanvas(await sampleCanvas(page));

    const rect = await page.locator("[data-testid='scene-canvas']").boundingBox();
    if (!rect) throw new Error("scene canvas bounding box is unavailable");

    await page.mouse.click(rect.x + rect.width * 0.4, rect.y + rect.height * 0.5);
    await page.waitForFunction(() => globalThis.__threeRbPickedName === "left-cube", null, { timeout: 5_000 });

    const leftPick = await page.evaluate(() => ({
      pickCount: globalThis.__threeRbPickCount,
      pickedName: globalThis.__threeRbPickedName,
      pickedDistance: globalThis.__threeRbPickedDistance,
      pickedPoint: globalThis.__threeRbPickedPoint,
      leftColor: globalThis.__threeRbLeftCube?.material?.color?.getHex?.(),
      rightColor: globalThis.__threeRbRightCube?.material?.color?.getHex?.(),
      renderInfo: globalThis.__threeRbRenderer?.info?.render
    }));

    if (leftPick.leftColor !== 0xffcc4d || leftPick.rightColor !== 0x4ed08f || !(leftPick.pickedDistance > 0)) {
      throw new Error(`left pick did not update the expected mesh: ${JSON.stringify(leftPick)}`);
    }

    await page.mouse.click(rect.x + rect.width * 0.6, rect.y + rect.height * 0.5);
    await page.waitForFunction(() => globalThis.__threeRbPickedName === "right-cube", null, { timeout: 5_000 });

    const rightPick = await page.evaluate(() => ({
      frame: globalThis.__threeRbPickingFrame,
      pickCount: globalThis.__threeRbPickCount,
      pickedName: globalThis.__threeRbPickedName,
      leftColor: globalThis.__threeRbLeftCube?.material?.color?.getHex?.(),
      rightColor: globalThis.__threeRbRightCube?.material?.color?.getHex?.(),
      renderInfo: globalThis.__threeRbRenderer?.info?.render
    }));

    if (rightPick.leftColor !== 0x4ed08f || rightPick.rightColor !== 0xffcc4d || rightPick.pickCount < 2) {
      throw new Error(`right pick did not update the expected mesh: ${JSON.stringify(rightPick)}`);
    }
    if (!rightPick.renderInfo || rightPick.renderInfo.triangles < 24 || !rightPick.frame) {
      throw new Error(`picking scene did not render or animate: ${JSON.stringify(rightPick)}`);
    }

    assertNoDiagnostics(diagnostics);

    console.log(`picking smoke test passed at ${server.url}/examples/browser/picking/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
