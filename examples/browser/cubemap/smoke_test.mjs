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

    await page.goto(`${server.url}/examples/browser/cubemap/`, { waitUntil: "load" });
    await waitForRunning(page, diagnostics);
    await page.waitForFunction(
      () => {
        const texture = globalThis.__threeRbCubeTexture;
        return texture?.isCubeTexture === true &&
          Array.isArray(texture.image) &&
          texture.image.length === 6 &&
          texture.image.every((image) => image?.complete === true);
      },
      null,
      { timeout: 10_000 }
    );
    await page.waitForTimeout(1_000);

    assertNonBlankCanvas(await sampleCanvas(page));

    const scene = await page.evaluate(() => ({
      frame: globalThis.__threeRbCubemapFrame,
      renderInfo: globalThis.__threeRbRenderer?.info?.render,
      cameraType: globalThis.__threeRbCamera?.type,
      sceneChildren: globalThis.__threeRbCubemapScene?.children?.length,
      meshType: globalThis.__threeRbCubemapMesh?.type,
      geometryType: globalThis.__threeRbCubemapMesh?.geometry?.type,
      materialType: globalThis.__threeRbCubemapMesh?.material?.type,
      materialRoughness: globalThis.__threeRbCubemapMaterial?.roughness,
      materialMetalness: globalThis.__threeRbCubemapMaterial?.metalness,
      cubeTextureType: globalThis.__threeRbCubeTexture?.isCubeTexture,
      cubeTextureImageCount: globalThis.__threeRbCubeTexture?.image?.length,
      backgroundType: globalThis.__threeRbCubemapScene?.background?.isCubeTexture,
      environmentType: globalThis.__threeRbCubemapScene?.environment?.isCubeTexture
    }));

    if (scene.cameraType !== "PerspectiveCamera") {
      throw new Error(`expected a PerspectiveCamera cubemap view: ${JSON.stringify(scene)}`);
    }
    if (scene.meshType !== "Mesh" || scene.geometryType !== "SphereGeometry") {
      throw new Error(`expected a sphere mesh: ${JSON.stringify(scene)}`);
    }
    if (scene.materialType !== "MeshStandardMaterial") {
      throw new Error(`expected MeshStandardMaterial: ${JSON.stringify(scene)}`);
    }
    if (scene.materialRoughness !== 0.18 || scene.materialMetalness !== 0.38) {
      throw new Error(`expected configured material values: ${JSON.stringify(scene)}`);
    }
    if (scene.cubeTextureType !== true || scene.cubeTextureImageCount !== 6) {
      throw new Error(`expected a loaded cube texture: ${JSON.stringify(scene)}`);
    }
    if (scene.backgroundType !== true || scene.environmentType !== true) {
      throw new Error(`expected scene background and environment cube textures: ${JSON.stringify(scene)}`);
    }
    if (!scene.renderInfo || scene.renderInfo.triangles < 500) {
      throw new Error(`renderer did not draw the cubemap scene: ${JSON.stringify(scene)}`);
    }
    if (!scene.frame) {
      throw new Error(`cubemap example animation did not advance: ${JSON.stringify(scene)}`);
    }

    assertNoDiagnostics(diagnostics);

    console.log(`cubemap smoke test passed at ${server.url}/examples/browser/cubemap/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
