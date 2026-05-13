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

    await page.goto(`${server.url}/examples/browser/gltf/`, { waitUntil: "load" });
    await waitForRunning(page, diagnostics);
    await page.waitForFunction(
      () => globalThis.__threeRbGltfScene?.children?.length > 0,
      null,
      { timeout: 10_000 }
    );
    await page.waitForTimeout(1_000);

    assertNonBlankCanvas(await sampleCanvas(page));

    const scene = await page.evaluate(() => ({
      frame: globalThis.__threeRbGltfFrame,
      renderInfo: globalThis.__threeRbRenderer?.info?.render,
      cameraType: globalThis.__threeRbCamera?.type,
      rootChildren: globalThis.__threeRbGltfRootScene?.children?.length,
      gltfType: globalThis.__threeRbGltfScene?.type,
      gltfIsObject3D: globalThis.__threeRbGltfScene?.isObject3D,
      gltfChildren: globalThis.__threeRbGltfScene?.children?.length
    }));

    if (scene.cameraType !== "PerspectiveCamera") {
      throw new Error(`expected a PerspectiveCamera glTF view: ${JSON.stringify(scene)}`);
    }
    if (scene.gltfIsObject3D !== true || scene.gltfChildren < 1) {
      throw new Error(`expected a loaded glTF Object3D scene: ${JSON.stringify(scene)}`);
    }
    if (!scene.renderInfo || scene.renderInfo.triangles < 1) {
      throw new Error(`renderer did not draw the glTF triangle: ${JSON.stringify(scene)}`);
    }
    if (!scene.frame) {
      throw new Error(`glTF example animation did not advance: ${JSON.stringify(scene)}`);
    }

    assertNoDiagnostics(diagnostics);

    console.log(`glTF smoke test passed at ${server.url}/examples/browser/gltf/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
