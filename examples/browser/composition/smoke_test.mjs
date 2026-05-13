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
    await page.waitForFunction(
      () => globalThis.__threeRbLambertMaterial?.map?.source?.data?.complete === true,
      null,
      { timeout: 10_000 }
    );
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
      textureType: globalThis.__threeRbTexture?.isTexture,
      materialTextureType: globalThis.__threeRbLambertMaterial?.map?.isTexture,
      materialTextureWidth: globalThis.__threeRbLambertMaterial?.map?.source?.data?.naturalWidth,
      materialTextureWrapS: globalThis.__threeRbLambertMaterial?.map?.wrapS,
      materialTextureWrapT: globalThis.__threeRbLambertMaterial?.map?.wrapT,
      materialTextureMagFilter: globalThis.__threeRbLambertMaterial?.map?.magFilter,
      materialTextureMinFilter: globalThis.__threeRbLambertMaterial?.map?.minFilter,
      materialTextureRepeat: globalThis.__threeRbLambertMaterial?.map?.repeat?.toArray?.(),
      sceneChildren: globalThis.__threeRbScene?.children?.length,
      ambientLightType: globalThis.__threeRbAmbientLight?.type,
      directionalLightType: globalThis.__threeRbDirectionalLight?.type,
      pointLightType: globalThis.__threeRbPointLight?.type,
      pointLightDistance: globalThis.__threeRbPointLight?.distance,
      pointLightDecay: globalThis.__threeRbPointLight?.decay,
      hemisphereLightType: globalThis.__threeRbHemisphereLight?.type,
      hemisphereLightGroundColor: globalThis.__threeRbHemisphereLight?.groundColor?.getHex?.(),
      hemisphereLightIntensity: globalThis.__threeRbHemisphereLight?.intensity,
      planeGeometryType: globalThis.__threeRbPlane?.geometry?.type,
      rigType: globalThis.__threeRbRig?.type,
      primaryParentType: globalThis.__threeRbPrimaryMesh?.parent?.type,
      primaryMaterialType: globalThis.__threeRbPrimaryMesh?.material?.type,
      satelliteParentType: globalThis.__threeRbSatelliteMesh?.parent?.type,
      sphereParentType: globalThis.__threeRbSphereMesh?.parent?.type,
      sphereGeometryType: globalThis.__threeRbSphereMesh?.geometry?.type,
      sphereMaterialType: globalThis.__threeRbSphereMesh?.material?.type,
      phongParentType: globalThis.__threeRbPhongMesh?.parent?.type,
      phongGeometryType: globalThis.__threeRbPhongMesh?.geometry?.type,
      phongMaterialType: globalThis.__threeRbPhongMesh?.material?.type,
      phongSpecular: globalThis.__threeRbPhongMaterial?.specular?.getHex?.(),
      phongShininess: globalThis.__threeRbPhongMaterial?.shininess,
      phongSpecularMapType: globalThis.__threeRbPhongMaterial?.specularMap?.isTexture,
      satelliteMaterialType: globalThis.__threeRbSatelliteMesh?.material?.type,
      normalMaterialFlatShading: globalThis.__threeRbNormalMaterial?.flatShading,
      standardMaterialRoughness: globalThis.__threeRbStandardMaterial?.roughness,
      standardMaterialMetalness: globalThis.__threeRbStandardMaterial?.metalness,
      materialDisposeEvent: globalThis.__threeRbMaterialDisposeEvent,
      textureDisposeEvent: globalThis.__threeRbTextureDisposeEvent,
      materialHandleCachedAfterDispose: globalThis.__threeRbMaterialHandleCachedAfterDispose,
      textureHandleCachedAfterDispose: globalThis.__threeRbTextureHandleCachedAfterDispose,
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
    if (scene.textureType !== true || scene.materialTextureType !== true || scene.materialTextureWidth <= 0) {
      throw new Error(`expected a loaded material texture: ${JSON.stringify(scene)}`);
    }
    if (scene.materialTextureWrapS !== 1000 || scene.materialTextureWrapT !== 1000 || scene.materialTextureMagFilter !== 1003 || scene.materialTextureMinFilter !== 1004) {
      throw new Error(`expected configured texture wrapping and filters: ${JSON.stringify(scene)}`);
    }
    if (!Array.isArray(scene.materialTextureRepeat) || scene.materialTextureRepeat[0] !== 2 || scene.materialTextureRepeat[1] !== 2) {
      throw new Error(`expected configured texture repeat: ${JSON.stringify(scene)}`);
    }
    if (scene.ambientLightType !== "AmbientLight" || scene.directionalLightType !== "DirectionalLight" || scene.pointLightType !== "PointLight" || scene.hemisphereLightType !== "HemisphereLight") {
      throw new Error(`expected ambient, directional, point, and hemisphere lights: ${JSON.stringify(scene)}`);
    }
    if (scene.pointLightDistance !== 7 || scene.pointLightDecay !== 2) {
      throw new Error(`expected configured PointLight falloff: ${JSON.stringify(scene)}`);
    }
    if (scene.hemisphereLightGroundColor !== 0x1d2a20 || scene.hemisphereLightIntensity !== 0.28) {
      throw new Error(`expected configured HemisphereLight: ${JSON.stringify(scene)}`);
    }
    if (scene.rigType !== "Group" || scene.primaryParentType !== "Group" || scene.satelliteParentType !== "Group" || scene.sphereParentType !== "Group" || scene.phongParentType !== "Group") {
      throw new Error(`expected grouped child meshes: ${JSON.stringify(scene)}`);
    }
    if (scene.primaryMaterialType !== "MeshLambertMaterial") {
      throw new Error(`expected a light-reactive MeshLambertMaterial primary mesh: ${JSON.stringify(scene)}`);
    }
    if (scene.sphereGeometryType !== "SphereGeometry") {
      throw new Error(`expected a SphereGeometry child mesh: ${JSON.stringify(scene)}`);
    }
    if (scene.sphereMaterialType !== "MeshStandardMaterial" || scene.standardMaterialRoughness !== 0.38 || scene.standardMaterialMetalness !== 0.45) {
      throw new Error(`expected a configured MeshStandardMaterial sphere: ${JSON.stringify(scene)}`);
    }
    if (scene.phongGeometryType !== "SphereGeometry" || scene.phongMaterialType !== "MeshPhongMaterial") {
      throw new Error(`expected a MeshPhongMaterial highlight sphere: ${JSON.stringify(scene)}`);
    }
    if (scene.phongSpecular !== 0xffffff || scene.phongShininess !== 72 || scene.phongSpecularMapType !== true) {
      throw new Error(`expected configured MeshPhongMaterial specular settings: ${JSON.stringify(scene)}`);
    }
    if (scene.satelliteMaterialType !== "MeshNormalMaterial" || scene.normalMaterialFlatShading !== true) {
      throw new Error(`expected a flat-shaded MeshNormalMaterial satellite: ${JSON.stringify(scene)}`);
    }
    if (scene.materialDisposeEvent !== true || scene.textureDisposeEvent !== true) {
      throw new Error(`expected material and texture dispose events: ${JSON.stringify(scene)}`);
    }
    if (scene.materialHandleCachedAfterDispose !== false || scene.textureHandleCachedAfterDispose !== false) {
      throw new Error(`expected disposed material and texture handles to leave the backend cache: ${JSON.stringify(scene)}`);
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
