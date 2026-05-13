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
      controlsType: globalThis.__threeRbControls?.constructor?.name,
      controlsEnableDamping: globalThis.__threeRbControls?.enableDamping,
      controlsEnablePan: globalThis.__threeRbControls?.enablePan,
      controlsTarget: globalThis.__threeRbControls?.target?.toArray?.(),
      sceneChildren: globalThis.__threeRbScene?.children?.length,
      ambientLightType: globalThis.__threeRbAmbientLight?.type,
      directionalLightType: globalThis.__threeRbDirectionalLight?.type,
      planeGeometryType: globalThis.__threeRbPlane?.geometry?.type,
      rigType: globalThis.__threeRbRig?.type,
      primaryParentType: globalThis.__threeRbPrimaryMesh?.parent?.type,
      primaryMaterialType: globalThis.__threeRbPrimaryMesh?.material?.type,
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
    if (scene.controlsType !== "OrbitControls" || scene.controlsEnableDamping !== true || scene.controlsEnablePan !== false) {
      throw new Error(`expected configured OrbitControls: ${JSON.stringify(scene)}`);
    }
    if (scene.ambientLightType !== "AmbientLight" || scene.directionalLightType !== "DirectionalLight") {
      throw new Error(`expected ambient and directional lights: ${JSON.stringify(scene)}`);
    }
    if (scene.rigType !== "Group" || scene.primaryParentType !== "Group" || scene.satelliteParentType !== "Group" || scene.sphereParentType !== "Group") {
      throw new Error(`expected grouped child meshes: ${JSON.stringify(scene)}`);
    }
    if (scene.primaryMaterialType !== "MeshLambertMaterial") {
      throw new Error(`expected a light-reactive MeshLambertMaterial primary mesh: ${JSON.stringify(scene)}`);
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

    const beforeDrag = await page.evaluate(() => globalThis.__threeRbCamera?.position?.toArray?.());
    await page.mouse.move(480, 270);
    await page.mouse.down();
    await page.mouse.move(620, 300, { steps: 12 });
    await page.mouse.up();
    await page.waitForTimeout(500);
    const afterDrag = await page.evaluate(() => globalThis.__threeRbCamera?.position?.toArray?.());
    if (!cameraPositionChanged(beforeDrag, afterDrag)) {
      throw new Error(`OrbitControls drag did not move the camera: ${JSON.stringify({ beforeDrag, afterDrag })}`);
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

function cameraPositionChanged(before, after) {
  if (!Array.isArray(before) || !Array.isArray(after)) return false;

  return before.some((value, index) => Math.abs(value - after[index]) > 0.001);
}
