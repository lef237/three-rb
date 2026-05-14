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
      () => globalThis.__threeRbTextureMaterial?.map?.source?.data?.complete === true &&
        globalThis.__threeRbTextureExampleEnvironment?.isDataTexture === true,
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
      matcapMeshType: globalThis.__threeRbMatcapMesh?.type,
      matcapGeometryType: globalThis.__threeRbMatcapMesh?.geometry?.type,
      matcapMaterialType: globalThis.__threeRbMatcapMesh?.material?.type,
      matcapMaterialColor: globalThis.__threeRbMatcapMaterial?.color?.getHex?.(),
      matcapMaterialFlatShading: globalThis.__threeRbMatcapMaterial?.flatShading,
      matcapTextureType: globalThis.__threeRbMatcapMaterial?.matcap?.isTexture,
      matcapMapType: globalThis.__threeRbMatcapMaterial?.map?.isTexture,
      matcapTextureSame: globalThis.__threeRbMatcapMaterial?.matcap === globalThis.__threeRbTextureExampleTexture,
      matcapMapSame: globalThis.__threeRbMatcapMaterial?.map === globalThis.__threeRbTextureExampleTexture,
      materialRoughnessMapType: globalThis.__threeRbTextureMaterial?.roughnessMap?.isTexture,
      materialMetalnessMapType: globalThis.__threeRbTextureMaterial?.metalnessMap?.isTexture,
      materialAnisotropyMapType: globalThis.__threeRbTextureMaterial?.anisotropyMap?.isTexture,
      materialClearcoatMapType: globalThis.__threeRbTextureMaterial?.clearcoatMap?.isTexture,
      materialRoughness: globalThis.__threeRbTextureMaterial?.roughness,
      materialMetalness: globalThis.__threeRbTextureMaterial?.metalness,
      materialAnisotropy: globalThis.__threeRbTextureMaterial?.anisotropy,
      materialAnisotropyRotation: globalThis.__threeRbTextureMaterial?.anisotropyRotation,
      materialClearcoat: globalThis.__threeRbTextureMaterial?.clearcoat,
      materialClearcoatRoughness: globalThis.__threeRbTextureMaterial?.clearcoatRoughness,
      materialIor: globalThis.__threeRbTextureMaterial?.ior,
      materialSpecularIntensity: globalThis.__threeRbTextureMaterial?.specularIntensity,
      materialSpecularColor: globalThis.__threeRbTextureMaterial?.specularColor?.getHex?.(),
      textureType: globalThis.__threeRbTextureExampleTexture?.isTexture,
      textureWidth: globalThis.__threeRbTextureExampleTexture?.source?.data?.naturalWidth,
      textureWrapS: globalThis.__threeRbTextureExampleTexture?.wrapS,
      textureWrapT: globalThis.__threeRbTextureExampleTexture?.wrapT,
      textureMagFilter: globalThis.__threeRbTextureExampleTexture?.magFilter,
      textureMinFilter: globalThis.__threeRbTextureExampleTexture?.minFilter,
      textureOffset: globalThis.__threeRbTextureExampleTexture?.offset?.toArray?.(),
      textureRepeat: globalThis.__threeRbTextureExampleTexture?.repeat?.toArray?.(),
      textureCenter: globalThis.__threeRbTextureExampleTexture?.center?.toArray?.(),
      textureRotation: globalThis.__threeRbTextureExampleTexture?.rotation,
      textureMatrixAutoUpdate: globalThis.__threeRbTextureExampleTexture?.matrixAutoUpdate,
      environmentType: globalThis.__threeRbTextureExampleEnvironment?.isDataTexture,
      environmentMapping: globalThis.__threeRbTextureExampleEnvironment?.mapping,
      environmentColorSpace: globalThis.__threeRbTextureExampleEnvironment?.colorSpace,
      environmentMagFilter: globalThis.__threeRbTextureExampleEnvironment?.magFilter,
      environmentMinFilter: globalThis.__threeRbTextureExampleEnvironment?.minFilter,
      sceneEnvironmentSame: globalThis.__threeRbScene?.environment === globalThis.__threeRbTextureExampleEnvironment
    }));

    if (scene.cameraType !== "OrthographicCamera") {
      throw new Error(`expected an OrthographicCamera texture view: ${JSON.stringify(scene)}`);
    }
    if (scene.meshType !== "Mesh" || scene.geometryType !== "BoxGeometry") {
      throw new Error(`expected a textured box mesh: ${JSON.stringify(scene)}`);
    }
    if (scene.materialType !== "MeshPhysicalMaterial" || scene.materialMapType !== true) {
      throw new Error(`expected MeshPhysicalMaterial with a texture map: ${JSON.stringify(scene)}`);
    }
    if (scene.matcapMeshType !== "Mesh" || scene.matcapGeometryType !== "SphereGeometry") {
      throw new Error(`expected a matcap sphere mesh: ${JSON.stringify(scene)}`);
    }
    if (
      scene.matcapMaterialType !== "MeshMatcapMaterial" ||
      scene.matcapMaterialColor !== 0xffffff ||
      scene.matcapMaterialFlatShading !== true ||
      scene.matcapTextureType !== true ||
      scene.matcapMapType !== true ||
      scene.matcapTextureSame !== true ||
      scene.matcapMapSame !== true
    ) {
      throw new Error(`expected MeshMatcapMaterial with shared matcap/map texture: ${JSON.stringify(scene)}`);
    }
    if (scene.materialRoughnessMapType !== true || scene.materialMetalnessMapType !== true || scene.materialAnisotropyMapType !== true || scene.materialClearcoatMapType !== true) {
      throw new Error(`expected MeshPhysicalMaterial with PBR and physical texture maps: ${JSON.stringify(scene)}`);
    }
    if (scene.materialRoughness !== 0.42 || scene.materialMetalness !== 0.08) {
      throw new Error(`expected configured PBR material values: ${JSON.stringify(scene)}`);
    }
    if (scene.materialAnisotropy !== 0.25 || scene.materialAnisotropyRotation !== 0.15) {
      throw new Error(`expected configured anisotropy material values: ${JSON.stringify(scene)}`);
    }
    if (scene.materialClearcoat !== 0.65 || scene.materialClearcoatRoughness !== 0.18 || scene.materialIor !== 1.45) {
      throw new Error(`expected configured physical material values: ${JSON.stringify(scene)}`);
    }
    if (scene.materialSpecularIntensity !== 0.75 || scene.materialSpecularColor !== 0xe8f1ff) {
      throw new Error(`expected configured physical specular values: ${JSON.stringify(scene)}`);
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
    if (!Array.isArray(scene.textureOffset) || scene.textureOffset[0] !== 0.125 || scene.textureOffset[1] !== 0.25) {
      throw new Error(`expected configured texture offset: ${JSON.stringify(scene)}`);
    }
    if (!Array.isArray(scene.textureCenter) || scene.textureCenter[0] !== 0.5 || scene.textureCenter[1] !== 0.5) {
      throw new Error(`expected configured texture center: ${JSON.stringify(scene)}`);
    }
    if (Math.abs(scene.textureRotation - 0.35) > 1e-12 || scene.textureMatrixAutoUpdate !== true) {
      throw new Error(`expected configured texture transform state: ${JSON.stringify(scene)}`);
    }
    if (scene.environmentType !== true || scene.environmentMapping !== 303 || scene.environmentColorSpace !== "srgb-linear") {
      throw new Error(`expected an RGBE environment texture with equirectangular mapping: ${JSON.stringify(scene)}`);
    }
    if (scene.environmentMagFilter !== 1006 || scene.environmentMinFilter !== 1006 || scene.sceneEnvironmentSame !== true) {
      throw new Error(`expected configured RGBE environment texture filters and scene binding: ${JSON.stringify(scene)}`);
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
