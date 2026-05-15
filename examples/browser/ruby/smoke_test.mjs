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

async function redPixelCount(page) {
  return page.evaluate(() => {
    const element = document.querySelector("[data-testid='scene-canvas']");
    const gl = element.getContext("webgl2") || element.getContext("webgl");
    const width = element.width;
    const height = element.height;
    const pixels = new Uint8Array(width * height * 4);
    gl.readPixels(0, 0, width, height, gl.RGBA, gl.UNSIGNED_BYTE, pixels);

    let count = 0;
    for (let index = 0; index < pixels.length; index += 4) {
      const red = pixels[index];
      const green = pixels[index + 1];
      const blue = pixels[index + 2];
      if (red > 120 && red > green * 1.18 && red > blue * 1.12) count += 1;
    }
    return count;
  });
}

async function main() {
  const { chromium } = await loadPlaywright();
  const server = await startServer();
  const browser = await chromium.launch({ headless: process.env.HEADLESS !== "0" });
  const diagnostics = createDiagnostics();

  try {
    const page = await createSmokePage(browser, diagnostics, { viewport: { width: 1040, height: 680 } });

    await page.goto(`${server.url}/examples/browser/ruby/`, { waitUntil: "load" });
    await waitForRunning(page, diagnostics);
    await page.waitForTimeout(1_000);

    const canvas = await sampleCanvas(page);
    assertCanvasHasDimensions(canvas);
    if (canvas.nonBlankPixels === 0) {
      throw new Error(`canvas sample is blank: ${JSON.stringify(canvas)}`);
    }

    const debug = await page.evaluate(() => ({
      frame: globalThis.__threeRbRubyFrame,
      sceneChildren: globalThis.__threeRbScene?.children?.length,
      rubyType: globalThis.__threeRbRubyGem?.type,
      rubyGeometryType: globalThis.__threeRbRubyGeometry?.type,
      rubyPositionCount: globalThis.__threeRbRubyGeometry?.attributes?.position?.count,
      rubyMaterial: {
        type: globalThis.__threeRbRubyMaterial?.type,
        color: globalThis.__threeRbRubyMaterial?.color?.getHex?.(),
        transmission: globalThis.__threeRbRubyMaterial?.transmission,
        thickness: globalThis.__threeRbRubyMaterial?.thickness,
        ior: globalThis.__threeRbRubyMaterial?.ior,
        clearcoat: globalThis.__threeRbRubyMaterial?.clearcoat
      },
      titleType: globalThis.__threeRbRubyTitle?.type,
      titleGeometryType: globalThis.__threeRbRubyTitleGeometry?.type,
      titlePositionCount: globalThis.__threeRbRubyTitleGeometry?.attributes?.position?.count,
      fontLoaded: globalThis.__threeRbRubyFontLoaded,
      renderInfo: globalThis.__threeRbRenderer?.info?.render
    }));

    if (debug.rubyType !== "Mesh" || debug.rubyGeometryType !== "BufferGeometry") {
      throw new Error(`ruby gemstone was not materialized as expected: ${JSON.stringify(debug, null, 2)}`);
    }
    if (debug.rubyPositionCount < 240) {
      throw new Error(`ruby gemstone has too few facet vertices: ${JSON.stringify(debug, null, 2)}`);
    }
    if (debug.rubyMaterial.type !== "MeshPhysicalMaterial" || debug.rubyMaterial.transmission < 0.7) {
      throw new Error(`ruby material is not transmissive: ${JSON.stringify(debug, null, 2)}`);
    }
    if (debug.titleType !== "Mesh" || debug.titleGeometryType !== "TextGeometry" || !debug.fontLoaded) {
      throw new Error(`title text geometry did not load: ${JSON.stringify(debug, null, 2)}`);
    }
    if (debug.titlePositionCount < 200 || !debug.renderInfo || debug.renderInfo.triangles < 250) {
      throw new Error(`title did not render enough geometry: ${JSON.stringify(debug, null, 2)}`);
    }
    if (debug.frame <= 0) {
      throw new Error(`animation loop did not advance: ${JSON.stringify(debug, null, 2)}`);
    }

    const rubyPixels = await redPixelCount(page);
    if (rubyPixels < 500) {
      throw new Error(`ruby gemstone is not visibly red enough: redPixels=${rubyPixels}\n${JSON.stringify(debug, null, 2)}`);
    }

    assertNoDiagnostics(diagnostics);

    console.log(`ruby smoke test passed at ${server.url}/examples/browser/ruby/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
