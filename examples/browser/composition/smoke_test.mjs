import { createServer } from "node:http";
import { readFile, stat } from "node:fs/promises";
import { extname, join, normalize, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = fileURLToPath(new URL("../../..", import.meta.url));
const mimeTypes = new Map([
  [".html", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".mjs", "text/javascript; charset=utf-8"],
  [".rb", "text/plain; charset=utf-8"],
  [".css", "text/css; charset=utf-8"],
  [".wasm", "application/wasm"]
]);

async function main() {
  const { chromium } = await loadPlaywright();
  const server = await startServer();
  const browser = await chromium.launch({ headless: process.env.HEADLESS !== "0" });
  const errors = [];
  const requests = [];

  try {
    const page = await browser.newPage({ viewport: { width: 960, height: 540 } });
    page.on("console", (message) => {
      if (message.type() === "error") errors.push(message.text());
    });
    page.on("pageerror", (error) => errors.push(error.message));
    page.on("requestfailed", (request) => {
      const failure = request.failure();
      requests.push(`request failed: ${request.url()} ${failure ? failure.errorText : ""}`.trim());
    });
    page.on("response", (response) => {
      if (response.status() >= 400) requests.push(`response ${response.status()}: ${response.url()}`);
    });

    await page.goto(`${server.url}/examples/browser/composition/`, { waitUntil: "load" });
    await page.getByTestId("status").waitFor({ state: "visible", timeout: 5_000 });
    try {
      await page.waitForFunction(
        () => document.querySelector("[data-testid='status']")?.textContent === "Running",
        null,
        { timeout: 120_000 }
      );
    } catch (error) {
      const status = await page.getByTestId("status").textContent();
      throw new Error(diagnosticMessage(`timed out waiting for Running; current status: ${status}`, errors, requests), {
        cause: error
      });
    }
    await page.waitForTimeout(1_000);

    const canvas = await sampleCanvas(page);
    if (canvas.width <= 0 || canvas.height <= 0) {
      throw new Error(`canvas has invalid dimensions: ${canvas.width}x${canvas.height}`);
    }
    if (canvas.nonBlankPixels === 0) {
      throw new Error(`canvas sample is blank: ${JSON.stringify(canvas)}`);
    }

    const scene = await page.evaluate(() => ({
      frame: globalThis.__threeRbCompositionFrame,
      renderInfo: globalThis.__threeRbRenderer?.info?.render,
      sceneChildren: globalThis.__threeRbScene?.children?.length,
      planeGeometryType: globalThis.__threeRbPlane?.geometry?.type,
      rigType: globalThis.__threeRbRig?.type,
      primaryParentType: globalThis.__threeRbPrimaryMesh?.parent?.type,
      satelliteParentType: globalThis.__threeRbSatelliteMesh?.parent?.type,
      satelliteMaterialType: globalThis.__threeRbSatelliteMesh?.material?.type,
      normalMaterialFlatShading: globalThis.__threeRbNormalMaterial?.flatShading,
      currentMaterialColor: globalThis.__threeRbChangingMaterial?.color?.getHex?.(),
      initialMaterialColor: globalThis.__threeRbInitialMaterialColor
    }));

    if (scene.planeGeometryType !== "PlaneGeometry") {
      throw new Error(`expected a PlaneGeometry backdrop: ${JSON.stringify(scene)}`);
    }
    if (scene.rigType !== "Group" || scene.primaryParentType !== "Group" || scene.satelliteParentType !== "Group") {
      throw new Error(`expected grouped child meshes: ${JSON.stringify(scene)}`);
    }
    if (scene.satelliteMaterialType !== "MeshNormalMaterial" || scene.normalMaterialFlatShading !== true) {
      throw new Error(`expected a flat-shaded MeshNormalMaterial satellite: ${JSON.stringify(scene)}`);
    }
    if (!scene.renderInfo || scene.renderInfo.triangles < 26) {
      throw new Error(`renderer did not draw the composition triangles: ${JSON.stringify(scene)}`);
    }
    if (!scene.frame || scene.currentMaterialColor === scene.initialMaterialColor) {
      throw new Error(`material color did not change after animation frames: ${JSON.stringify(scene)}`);
    }
    if (errors.length > 0) {
      throw new Error(diagnosticMessage("browser console errors", errors, requests));
    }

    console.log(`composition smoke test passed at ${server.url}/examples/browser/composition/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

async function sampleCanvas(page) {
  return page.evaluate(() => {
    const element = document.querySelector("[data-testid='scene-canvas']");
    const gl = element.getContext("webgl2") || element.getContext("webgl");
    const width = element.width;
    const height = element.height;
    const pixels = new Uint8Array(width * height * 4);

    gl.readPixels(0, 0, width, height, gl.RGBA, gl.UNSIGNED_BYTE, pixels);

    let nonBlankPixels = 0;
    let nonTransparentPixels = 0;
    let maxRgb = 0;
    for (let index = 0; index < pixels.length; index += 4) {
      const rgb = pixels[index] + pixels[index + 1] + pixels[index + 2];
      if (rgb > 12) nonBlankPixels += 1;
      if (pixels[index + 3] > 0) nonTransparentPixels += 1;
      if (rgb > maxRgb) maxRgb = rgb;
    }

    return { width, height, nonBlankPixels, nonTransparentPixels, maxRgb };
  });
}

function diagnosticMessage(message, errors, requests) {
  const sections = [message];
  if (errors.length > 0) sections.push(`console/page errors:\n${errors.join("\n")}`);
  if (requests.length > 0) sections.push(`network diagnostics:\n${requests.join("\n")}`);
  return sections.join("\n\n");
}

async function loadPlaywright() {
  try {
    return await import("playwright");
  } catch (error) {
    throw new Error(
      "Playwright is required for the browser smoke test. Run `pnpm install` and `pnpm exec playwright install chromium` first.",
      { cause: error }
    );
  }
}

function startServer() {
  const server = createServer(async (request, response) => {
    try {
      const pathname = decodeURIComponent(new URL(request.url, "http://127.0.0.1").pathname);
      const filePath = await resolveFile(pathname);
      response.setHeader("Content-Type", mimeTypes.get(extname(filePath)) || "application/octet-stream");
      response.end(await readFile(filePath));
    } catch (error) {
      response.statusCode = error.code === "ENOENT" ? 404 : 500;
      response.end(error.message);
    }
  });

  return new Promise((resolve, reject) => {
    server.on("error", reject);
    server.listen(0, "127.0.0.1", () => {
      const { port } = server.address();
      resolve({ instance: server, url: `http://127.0.0.1:${port}` });
    });
  });
}

async function resolveFile(pathname) {
  const requested = pathname.endsWith("/") ? `${pathname}index.html` : pathname;
  const filePath = normalize(join(root, requested));
  const rel = relative(root, filePath);
  if (rel.startsWith("..")) throw new Error("request escaped repository root");

  const info = await stat(filePath);
  if (info.isDirectory()) return join(filePath, "index.html");
  return filePath;
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
