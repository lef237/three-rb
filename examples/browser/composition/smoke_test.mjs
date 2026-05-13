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

    await page.goto(`${server.url}/examples/browser/composition/`, { waitUntil: "load" });
    await waitForRunning(page, diagnostics);
    await page.waitForTimeout(1_000);

    assertNonBlankCanvas(await sampleCanvas(page));

    const scene = await page.evaluate(() => ({
      frame: globalThis.__threeRbCompositionFrame,
      renderInfo: globalThis.__threeRbRenderer?.info?.render,
      cameraType: globalThis.__threeRbCamera?.type,
      sceneChildren: globalThis.__threeRbScene?.children?.length,
      planeGeometryType: globalThis.__threeRbPlane?.geometry?.type,
      rigType: globalThis.__threeRbRig?.type,
      primaryParentType: globalThis.__threeRbPrimaryMesh?.parent?.type,
      satelliteParentType: globalThis.__threeRbSatelliteMesh?.parent?.type,
      sphereParentType: globalThis.__threeRbSphereMesh?.parent?.type,
      sphereGeometryType: globalThis.__threeRbSphereMesh?.geometry?.type,
      satelliteMaterialType: globalThis.__threeRbSatelliteMesh?.material?.type,
      normalMaterialFlatShading: globalThis.__threeRbNormalMaterial?.flatShading,
      currentMaterialColor: globalThis.__threeRbChangingMaterial?.color?.getHex?.(),
      initialMaterialColor: globalThis.__threeRbInitialMaterialColor
    }));

    if (scene.planeGeometryType !== "PlaneGeometry") {
      throw new Error(`expected a PlaneGeometry backdrop: ${JSON.stringify(scene)}`);
    }
    if (scene.cameraType !== "OrthographicCamera") {
      throw new Error(`expected an OrthographicCamera composition view: ${JSON.stringify(scene)}`);
    }
    if (scene.rigType !== "Group" || scene.primaryParentType !== "Group" || scene.satelliteParentType !== "Group" || scene.sphereParentType !== "Group") {
      throw new Error(`expected grouped child meshes: ${JSON.stringify(scene)}`);
    }
    if (scene.sphereGeometryType !== "SphereGeometry") {
      throw new Error(`expected a SphereGeometry child mesh: ${JSON.stringify(scene)}`);
    }
    if (scene.satelliteMaterialType !== "MeshNormalMaterial" || scene.normalMaterialFlatShading !== true) {
      throw new Error(`expected a flat-shaded MeshNormalMaterial satellite: ${JSON.stringify(scene)}`);
    }
    if (!scene.renderInfo || scene.renderInfo.triangles < 200) {
      throw new Error(`renderer did not draw the composition triangles: ${JSON.stringify(scene)}`);
    }
    if (!scene.frame || scene.currentMaterialColor === scene.initialMaterialColor) {
      throw new Error(`material color did not change after animation frames: ${JSON.stringify(scene)}`);
    }
    assertNoDiagnostics(diagnostics);

    console.log(`composition smoke test passed at ${server.url}/examples/browser/composition/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
