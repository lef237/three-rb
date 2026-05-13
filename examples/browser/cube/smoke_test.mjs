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

    await page.goto(`${server.url}/examples/browser/cube/`, { waitUntil: "load" });
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

    const canvas = await page.evaluate(() => {
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

    if (canvas.width <= 0 || canvas.height <= 0) {
      throw new Error(`canvas has invalid dimensions: ${canvas.width}x${canvas.height}`);
    }
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
    if (errors.length > 0) {
      throw new Error(diagnosticMessage("browser console errors", errors, requests));
    }

    console.log(`cube smoke test passed at ${server.url}/examples/browser/cube/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
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
