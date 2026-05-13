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

    await page.goto(`${server.url}/examples/browser/textures/`, { waitUntil: "load" });
    await waitForRunning(page, diagnostics);
    await page.waitForFunction(
      () => globalThis.__threeRbTextureMaterial?.map?.source?.data?.complete === true,
      null,
      { timeout: 10_000 }
    );
    await page.waitForTimeout(1_000);

    assertNonBlankCanvas(await sampleCanvas(page));

    const scene = await page.evaluate(() => ({
      frame: globalThis.__threeRbTextureExampleFrame,
      renderInfo: globalThis.__threeRbRenderer?.info?.render,
      cameraType: globalThis.__threeRbCamera?.type,
      sceneChildren: globalThis.__threeRbScene?.children?.length,
      meshType: globalThis.__threeRbTexturedMesh?.type,
      geometryType: globalThis.__threeRbTexturedMesh?.geometry?.type,
      materialType: globalThis.__threeRbTexturedMesh?.material?.type,
      materialMapType: globalThis.__threeRbTexturedMesh?.material?.map?.isTexture,
      materialRoughness: globalThis.__threeRbTextureMaterial?.roughness,
      materialMetalness: globalThis.__threeRbTextureMaterial?.metalness,
      textureType: globalThis.__threeRbTextureExampleTexture?.isTexture,
      textureWidth: globalThis.__threeRbTextureExampleTexture?.source?.data?.naturalWidth,
      textureWrapS: globalThis.__threeRbTextureExampleTexture?.wrapS,
      textureWrapT: globalThis.__threeRbTextureExampleTexture?.wrapT,
      textureMagFilter: globalThis.__threeRbTextureExampleTexture?.magFilter,
      textureMinFilter: globalThis.__threeRbTextureExampleTexture?.minFilter,
      textureRepeat: globalThis.__threeRbTextureExampleTexture?.repeat?.toArray?.()
    }));

    if (scene.cameraType !== "OrthographicCamera") {
      throw new Error(`expected an OrthographicCamera texture view: ${JSON.stringify(scene)}`);
    }
    if (scene.meshType !== "Mesh" || scene.geometryType !== "BoxGeometry") {
      throw new Error(`expected a textured box mesh: ${JSON.stringify(scene)}`);
    }
    if (scene.materialType !== "MeshStandardMaterial" || scene.materialMapType !== true) {
      throw new Error(`expected MeshStandardMaterial with a texture map: ${JSON.stringify(scene)}`);
    }
    if (scene.materialRoughness !== 0.42 || scene.materialMetalness !== 0.08) {
      throw new Error(`expected configured PBR material values: ${JSON.stringify(scene)}`);
    }
    if (scene.textureType !== true || scene.textureWidth <= 0) {
      throw new Error(`expected a loaded texture: ${JSON.stringify(scene)}`);
    }
    if (scene.textureWrapS !== 1000 || scene.textureWrapT !== 1000 || scene.textureMagFilter !== 1003 || scene.textureMinFilter !== 1004) {
      throw new Error(`expected configured texture wrapping and filters: ${JSON.stringify(scene)}`);
    }
    if (!Array.isArray(scene.textureRepeat) || scene.textureRepeat[0] !== 4 || scene.textureRepeat[1] !== 3) {
      throw new Error(`expected configured texture repeat: ${JSON.stringify(scene)}`);
    }
    if (!scene.renderInfo || scene.renderInfo.triangles < 12) {
      throw new Error(`renderer did not draw the textured cube triangles: ${JSON.stringify(scene)}`);
    }
    if (!scene.frame) {
      throw new Error(`texture example animation did not advance: ${JSON.stringify(scene)}`);
    }

    assertNoDiagnostics(diagnostics);

    console.log(`textures smoke test passed at ${server.url}/examples/browser/textures/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
