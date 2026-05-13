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
  [".svg", "image/svg+xml"],
  [".gltf", "model/gltf+json"],
  [".hdr", "image/vnd.radiance"],
  [".wasm", "application/wasm"]
]);

export function createDiagnostics() {
  return { errors: [], requests: [] };
}

export async function loadPlaywright() {
  try {
    return await import("playwright");
  } catch (error) {
    throw new Error(
      "Playwright is required for the browser smoke test. Run `pnpm install` and `pnpm exec playwright install chromium` first.",
      { cause: error }
    );
  }
}

export async function createSmokePage(browser, diagnostics, options = {}) {
  const page = await browser.newPage({ viewport: options.viewport || { width: 960, height: 540 } });
  page.on("console", (message) => {
    if (message.type() === "error") diagnostics.errors.push(message.text());
  });
  page.on("pageerror", (error) => diagnostics.errors.push(error.message));
  page.on("requestfailed", (request) => {
    const failure = request.failure();
    diagnostics.requests.push(`request failed: ${request.url()} ${failure ? failure.errorText : ""}`.trim());
  });
  page.on("response", (response) => {
    if (response.status() >= 400) diagnostics.requests.push(`response ${response.status()}: ${response.url()}`);
  });
  return page;
}

export async function waitForRunning(page, diagnostics, timeout = 120_000) {
  await page.getByTestId("status").waitFor({ state: "visible", timeout: 5_000 });
  try {
    await page.waitForFunction(
      () => document.querySelector("[data-testid='status']")?.textContent === "Running",
      null,
      { timeout }
    );
  } catch (error) {
    const status = await page.getByTestId("status").textContent();
    throw new Error(diagnosticMessage(`timed out waiting for Running; current status: ${status}`, diagnostics), {
      cause: error
    });
  }
}

export async function sampleCanvas(page) {
  return page.evaluate(() => {
    const element = document.querySelector("[data-testid='scene-canvas']");
    if (!element) return { width: 0, height: 0, nonBlankPixels: 0, nonTransparentPixels: 0, maxRgb: 0 };

    const gl = element.getContext("webgl2") || element.getContext("webgl");
    if (!gl) throw new Error("canvas WebGL context is not available");

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

export function assertCanvasHasDimensions(canvas) {
  if (canvas.width <= 0 || canvas.height <= 0) {
    throw new Error(`canvas has invalid dimensions: ${canvas.width}x${canvas.height}`);
  }
}

export function assertNonBlankCanvas(canvas) {
  assertCanvasHasDimensions(canvas);
  if (canvas.nonBlankPixels === 0) {
    throw new Error(`canvas sample is blank: ${JSON.stringify(canvas)}`);
  }
}

export function assertNoDiagnostics(diagnostics) {
  if (diagnostics.errors.length > 0 || diagnostics.requests.length > 0) {
    throw new Error(diagnosticMessage("browser diagnostics", diagnostics));
  }
}

export function diagnosticMessage(message, diagnostics) {
  const sections = [message];
  if (diagnostics.errors.length > 0) sections.push(`console/page errors:\n${diagnostics.errors.join("\n")}`);
  if (diagnostics.requests.length > 0) sections.push(`network diagnostics:\n${diagnostics.requests.join("\n")}`);
  return sections.join("\n\n");
}

export function startServer() {
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
