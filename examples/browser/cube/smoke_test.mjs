import {
  assertCanvasHasDimensions,
  assertNoDiagnostics,
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

    await page.goto(`${server.url}/examples/browser/cube/`, { waitUntil: "load" });
    await waitForRunning(page, diagnostics);
    await page.waitForTimeout(1_000);

    const canvas = await sampleCanvas(page);
    assertCanvasHasDimensions(canvas);
    if (canvas.nonBlankPixels === 0) {
      const debug = await page.evaluate(() => ({
        sceneChildren: globalThis.__threeRbScene?.children?.length,
        cubeType: globalThis.__threeRbCube?.type,
        cubeVisible: globalThis.__threeRbCube?.visible,
        cubeParentType: globalThis.__threeRbCube?.parent?.type,
        cubePosition: globalThis.__threeRbCube?.position?.toArray?.(),
        cubeScale: globalThis.__threeRbCube?.scale?.toArray?.(),
        geometryType: globalThis.__threeRbCube?.geometry?.type,
        geometryBoundingSphere: globalThis.__threeRbCube?.geometry?.boundingSphere,
        materialType: globalThis.__threeRbCube?.material?.type,
        materialKeys: globalThis.__threeRbCube?.material ? Object.keys(globalThis.__threeRbCube.material).slice(0, 20) : undefined,
        materialColorType: globalThis.__threeRbCube?.material?.color?.constructor?.name,
        materialColor: globalThis.__threeRbCube?.material?.color?.getHex?.(),
        materialSide: globalThis.__threeRbCube?.material?.side,
        materialOpacity: globalThis.__threeRbCube?.material?.opacity,
        materialTransparent: globalThis.__threeRbCube?.material?.transparent,
        materialVisible: globalThis.__threeRbCube?.material?.visible,
        cameraType: globalThis.__threeRbCamera?.type,
        cameraPosition: globalThis.__threeRbCamera?.position?.toArray?.(),
        cameraFov: globalThis.__threeRbCamera?.fov,
        cameraAspect: globalThis.__threeRbCamera?.aspect,
        cameraNear: globalThis.__threeRbCamera?.near,
        cameraFar: globalThis.__threeRbCamera?.far,
        domElementSize: globalThis.__threeRbRenderer?.domElement && {
          width: globalThis.__threeRbRenderer.domElement.width,
          height: globalThis.__threeRbRenderer.domElement.height,
          clientWidth: globalThis.__threeRbRenderer.domElement.clientWidth,
          clientHeight: globalThis.__threeRbRenderer.domElement.clientHeight
        },
        rendererInfo: globalThis.__threeRbRenderer?.info?.render,
        renderHelperType: typeof globalThis.__threeRbRender,
        renderHelperCount: globalThis.__threeRbRenderCount,
        renderHelperFrameCount: globalThis.__threeRbRenderFrameCount,
        currentSceneChildren: globalThis.__threeRbCurrentScene?.children?.length,
        currentCameraPosition: globalThis.__threeRbCurrentCamera?.position?.toArray?.(),
        currentRendererMatches: globalThis.__threeRbCurrentRenderer === globalThis.__threeRbRenderer,
        currentSceneMatches: globalThis.__threeRbCurrentScene === globalThis.__threeRbScene,
        currentCameraMatches: globalThis.__threeRbCurrentCamera === globalThis.__threeRbCamera
      }));
      const direct = await page.evaluate(() => {
        const renderer = globalThis.__threeRbRenderer;
        renderer.setClearColor(0xff0000, 1);
        renderer.clear(true, true, true);
        renderer.render(globalThis.__threeRbScene, globalThis.__threeRbCamera);

        const gl = renderer.domElement.getContext("webgl2") || renderer.domElement.getContext("webgl");
        const corner = new Uint8Array(4);
        const center = new Uint8Array(4);
        gl.readPixels(0, 0, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, corner);
        gl.readPixels(Math.floor(renderer.domElement.width / 2), Math.floor(renderer.domElement.height / 2), 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, center);
        return { corner: Array.from(corner), center: Array.from(center), info: renderer.info.render };
      });
      throw new Error(`canvas sample is blank: ${JSON.stringify(canvas)} directClearPixel=${JSON.stringify(direct)}\n${JSON.stringify(debug, null, 2)}`);
    }

    const renderInfo = await page.evaluate(() => globalThis.__threeRbRenderer?.info?.render);
    if (!renderInfo || renderInfo.triangles < 12) {
      throw new Error(`renderer did not draw the cube triangles: ${JSON.stringify(renderInfo)}`);
    }
    assertNoDiagnostics(diagnostics);

    console.log(`cube smoke test passed at ${server.url}/examples/browser/cube/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
