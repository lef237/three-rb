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

    await page.goto(`${server.url}/examples/browser/dango/`, { waitUntil: "load" });
    await waitForRunning(page, diagnostics);
    await page.waitForTimeout(1_000);

    assertNonBlankCanvas(await sampleCanvas(page));

    const state = await page.evaluate(() => ({
      frame: globalThis.__threeRbDangoFrame,
      group: {
        type: globalThis.__threeRbDangoGroup?.type,
        name: globalThis.__threeRbDangoGroup?.name,
        children: globalThis.__threeRbDangoGroup?.children?.length,
        rotation: globalThis.__threeRbDangoGroup?.rotation?.toArray?.(),
        position: globalThis.__threeRbDangoGroup?.position?.toArray?.()
      },
      mochi: globalThis.__threeRbDangoMochi?.map((mesh) => ({
        type: mesh?.type,
        name: mesh?.name,
        geometryType: mesh?.geometry?.type,
        materialType: mesh?.material?.type,
        color: mesh?.material?.color?.getHex?.(),
        shininess: mesh?.material?.shininess,
        castShadow: mesh?.castShadow,
        receiveShadow: mesh?.receiveShadow,
        scale: mesh?.scale?.toArray?.()
      })),
      skewer: {
        type: globalThis.__threeRbDangoSkewer?.type,
        name: globalThis.__threeRbDangoSkewer?.name,
        children: globalThis.__threeRbDangoSkewer?.children?.length,
        position: globalThis.__threeRbDangoSkewer?.position?.toArray?.(),
        coreType: globalThis.__threeRbDangoSkewerCore?.type,
        coreGeometryType: globalThis.__threeRbDangoSkewerCore?.geometry?.type,
        coreWidth: globalThis.__threeRbDangoSkewerCore?.geometry?.parameters?.width,
        corePosition: globalThis.__threeRbDangoSkewerCore?.position?.toArray?.(),
        coreColor: globalThis.__threeRbDangoSkewerCore?.material?.color?.getHex?.(),
        coreCastShadow: globalThis.__threeRbDangoSkewerCore?.castShadow,
        tipType: globalThis.__threeRbDangoSkewerTip?.type,
        tipGeometryType: globalThis.__threeRbDangoSkewerTip?.geometry?.type,
        tipWidth: globalThis.__threeRbDangoSkewerTip?.geometry?.parameters?.width,
        tipPosition: globalThis.__threeRbDangoSkewerTip?.position?.toArray?.(),
        tipColor: globalThis.__threeRbDangoSkewerTip?.material?.color?.getHex?.(),
        tipCastShadow: globalThis.__threeRbDangoSkewerTip?.castShadow
      },
      plate: {
        type: globalThis.__threeRbDangoPlate?.type,
        name: globalThis.__threeRbDangoPlate?.name,
        children: globalThis.__threeRbDangoPlate?.children?.length,
        rotation: globalThis.__threeRbDangoPlate?.rotation?.toArray?.(),
        floorType: globalThis.__threeRbDangoPlateFloor?.type,
        floorGeometryType: globalThis.__threeRbDangoPlateFloor?.geometry?.type,
        frontRimType: globalThis.__threeRbDangoPlateFrontRim?.type,
        frontRimGeometryType: globalThis.__threeRbDangoPlateFrontRim?.geometry?.type,
        backRimType: globalThis.__threeRbDangoPlateBackRim?.type,
        backRimGeometryType: globalThis.__threeRbDangoPlateBackRim?.geometry?.type,
        leftRimType: globalThis.__threeRbDangoPlateLeftRim?.type,
        leftRimGeometryType: globalThis.__threeRbDangoPlateLeftRim?.geometry?.type,
        rightRimType: globalThis.__threeRbDangoPlateRightRim?.type,
        rightRimGeometryType: globalThis.__threeRbDangoPlateRightRim?.geometry?.type,
        footType: globalThis.__threeRbDangoPlateFoot?.type,
        footGeometryType: globalThis.__threeRbDangoPlateFoot?.geometry?.type,
        floorReceiveShadow: globalThis.__threeRbDangoPlateFloor?.receiveShadow,
        frontRimReceiveShadow: globalThis.__threeRbDangoPlateFrontRim?.receiveShadow,
        backRimReceiveShadow: globalThis.__threeRbDangoPlateBackRim?.receiveShadow,
        leftRimReceiveShadow: globalThis.__threeRbDangoPlateLeftRim?.receiveShadow,
        rightRimReceiveShadow: globalThis.__threeRbDangoPlateRightRim?.receiveShadow,
        footReceiveShadow: globalThis.__threeRbDangoPlateFoot?.receiveShadow
      },
      lights: {
        keyType: globalThis.__threeRbDangoKeyLight?.type,
        keyCastShadow: globalThis.__threeRbDangoKeyLight?.castShadow,
        hemisphereType: globalThis.__threeRbDangoHemisphereLight?.type,
        fillType: globalThis.__threeRbDangoFillLight?.type
      },
      controls: {
        autoRotate: globalThis.__threeRbControls?.autoRotate,
        enableDamping: globalThis.__threeRbControls?.enableDamping
      },
      renderInfo: globalThis.__threeRbRenderer?.info?.render
    }));

    if (state.group.type !== "Group" || state.group.name !== "dango-skewer" || state.group.children !== 4) {
      throw new Error(`dango group did not materialize correctly: ${JSON.stringify(state)}`);
    }
    if (!Array.isArray(state.group.rotation) || Math.abs(state.group.rotation[2] + 0.22) > 1e-12) {
      throw new Error(`dango group did not keep the expected skewer angle: ${JSON.stringify(state)}`);
    }
    if (!Array.isArray(state.mochi) || state.mochi.length !== 3) {
      throw new Error(`expected three mochi meshes: ${JSON.stringify(state)}`);
    }

    const expectedColors = [0xf8cfd7, 0xfffaed, 0xc0dca4];
    state.mochi.forEach((mesh, index) => {
      if (
        mesh.type !== "Mesh" ||
        mesh.geometryType !== "SphereGeometry" ||
        mesh.materialType !== "MeshPhongMaterial" ||
        mesh.color !== expectedColors[index] ||
        mesh.shininess !== 14 ||
        mesh.castShadow !== true ||
        mesh.receiveShadow !== true
      ) {
        throw new Error(`mochi mesh ${index} did not materialize correctly: ${JSON.stringify(state)}`);
      }
      if (!Array.isArray(mesh.scale) || mesh.scale[0] !== 1 || mesh.scale[1] !== 0.96 || mesh.scale[2] !== 0.88) {
        throw new Error(`mochi mesh ${index} scale did not sync: ${JSON.stringify(state)}`);
      }
    });

    if (
      state.skewer.type !== "Group" ||
      state.skewer.name !== "dango-skewer-rod" ||
      state.skewer.children !== 2 ||
      !Array.isArray(state.skewer.position) ||
      state.skewer.position[0] !== 0 ||
      state.skewer.coreType !== "Mesh" ||
      state.skewer.coreGeometryType !== "BoxGeometry" ||
      state.skewer.coreColor !== 0xcbb281 ||
      state.skewer.coreCastShadow !== true ||
      typeof state.skewer.coreWidth !== "number" ||
      state.skewer.coreWidth < 2.4 ||
      state.skewer.coreWidth > 2.7 ||
      !Array.isArray(state.skewer.corePosition) ||
      state.skewer.corePosition[0] !== 0 ||
      state.skewer.tipType !== "Mesh" ||
      state.skewer.tipGeometryType !== "BoxGeometry" ||
      state.skewer.tipColor !== 0xcbb281 ||
      state.skewer.tipCastShadow !== true ||
      typeof state.skewer.tipWidth !== "number" ||
      state.skewer.tipWidth < 0.6 ||
      state.skewer.tipWidth > 0.8 ||
      !Array.isArray(state.skewer.tipPosition) ||
      state.skewer.tipPosition[0] <= 1.6
    ) {
      throw new Error(`skewer did not materialize correctly: ${JSON.stringify(state)}`);
    }
    if (
      state.plate.type !== "Group" ||
      state.plate.name !== "dango-plate" ||
      state.plate.children !== 6 ||
      !Array.isArray(state.plate.rotation) ||
      state.plate.rotation[0] >= -0.4 ||
      state.plate.floorType !== "Mesh" ||
      state.plate.floorGeometryType !== "BoxGeometry" ||
      state.plate.frontRimType !== "Mesh" ||
      state.plate.frontRimGeometryType !== "BoxGeometry" ||
      state.plate.backRimType !== "Mesh" ||
      state.plate.backRimGeometryType !== "BoxGeometry" ||
      state.plate.leftRimType !== "Mesh" ||
      state.plate.leftRimGeometryType !== "BoxGeometry" ||
      state.plate.rightRimType !== "Mesh" ||
      state.plate.rightRimGeometryType !== "BoxGeometry" ||
      state.plate.footType !== "Mesh" ||
      state.plate.footGeometryType !== "BoxGeometry" ||
      state.plate.floorReceiveShadow !== true ||
      state.plate.frontRimReceiveShadow !== true ||
      state.plate.backRimReceiveShadow !== true ||
      state.plate.leftRimReceiveShadow !== true ||
      state.plate.rightRimReceiveShadow !== true ||
      state.plate.footReceiveShadow !== true
    ) {
      throw new Error(`plate did not materialize correctly: ${JSON.stringify(state)}`);
    }
    if (
      state.lights.keyType !== "DirectionalLight" ||
      state.lights.keyCastShadow !== true ||
      state.lights.hemisphereType !== "HemisphereLight" ||
      state.lights.fillType !== "PointLight"
    ) {
      throw new Error(`dango lights did not materialize correctly: ${JSON.stringify(state)}`);
    }
    if (state.controls.autoRotate !== false || state.controls.enableDamping !== true) {
      throw new Error(`orbit controls did not expose expected settings: ${JSON.stringify(state)}`);
    }
    if (!state.renderInfo || state.renderInfo.triangles < 2_000 || !state.frame) {
      throw new Error(`dango scene did not render or animate: ${JSON.stringify(state)}`);
    }

    assertNoDiagnostics(diagnostics);

    console.log(`dango smoke test passed at ${server.url}/examples/browser/dango/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
