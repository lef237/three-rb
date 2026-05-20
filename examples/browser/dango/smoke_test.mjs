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
        geometryType: globalThis.__threeRbDangoSkewer?.geometry?.type,
        materialType: globalThis.__threeRbDangoSkewer?.material?.type,
        color: globalThis.__threeRbDangoSkewer?.material?.color?.getHex?.(),
        castShadow: globalThis.__threeRbDangoSkewer?.castShadow,
        width: globalThis.__threeRbDangoSkewer?.geometry?.parameters?.width
      },
      plate: {
        type: globalThis.__threeRbDangoPlate?.type,
        geometryType: globalThis.__threeRbDangoPlate?.geometry?.type,
        receiveShadow: globalThis.__threeRbDangoPlate?.receiveShadow
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
    if (!Array.isArray(state.group.rotation) || Math.abs(state.group.rotation[1]) <= 0.001) {
      throw new Error(`dango group did not animate: ${JSON.stringify(state)}`);
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
      state.skewer.type !== "Mesh" ||
      state.skewer.geometryType !== "BoxGeometry" ||
      state.skewer.materialType !== "MeshLambertMaterial" ||
      state.skewer.color !== 0xcbb281 ||
      state.skewer.castShadow !== true ||
      typeof state.skewer.width !== "number" ||
      state.skewer.width >= 3
    ) {
      throw new Error(`skewer did not materialize correctly: ${JSON.stringify(state)}`);
    }
    if (state.plate.type !== "Mesh" || state.plate.geometryType !== "SphereGeometry" || state.plate.receiveShadow !== true) {
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
    if (state.controls.autoRotate !== true || state.controls.enableDamping !== true) {
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
