// Generates apps with `three-rb browser` into a temporary project, installs
// their packages the way the generated README says, and boots them in
// Chromium. The file-level generator tests can't tell whether a generated app
// actually installs and loads, for example when pnpm rejects its package.json
// or the shared boot script imports a file the generator doesn't copy.
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import {
  assertNoDiagnostics,
  createDiagnostics,
  createSmokePage,
  loadPlaywright,
  startServer,
  waitForRunning
} from "../../examples/browser/shared/smoke_test_helpers.mjs";

const repoRoot = fileURLToPath(new URL("../..", import.meta.url));
const examples = ["quickstart", "ruby"];

function run(command, args, cwd) {
  const result = spawnSync(command, args, { cwd, encoding: "utf8" });
  if (result.status !== 0) {
    throw new Error(`${[command, ...args].join(" ")} failed:\n${result.stdout}${result.stderr}`);
  }
}

function generate(appRoot, example) {
  run("ruby", ["-I", join(repoRoot, "lib"), join(repoRoot, "exe/three-rb"), "browser", `examples/browser/${example}`], appRoot);
}

// Generated apps don't set preserveDrawingBuffer, so gl.readPixels would see a
// cleared buffer. Screenshot the composited canvas instead and require that
// part of it differs from the clear color in its corner.
async function assertCanvasRendered(page, example) {
  const png = await page.getByTestId("scene-canvas").screenshot();
  const drawn = await page.evaluate(async (data) => {
    const image = await createImageBitmap(await (await fetch(`data:image/png;base64,${data}`)).blob());
    const canvas = new OffscreenCanvas(image.width, image.height);
    const context = canvas.getContext("2d");
    context.drawImage(image, 0, 0);
    const pixels = context.getImageData(0, 0, image.width, image.height).data;
    let differing = 0;
    for (let index = 0; index < pixels.length; index += 4) {
      const delta = Math.max(
        Math.abs(pixels[index] - pixels[0]),
        Math.abs(pixels[index + 1] - pixels[1]),
        Math.abs(pixels[index + 2] - pixels[2])
      );
      if (delta > 16) differing += 1;
    }
    return differing / (image.width * image.height);
  }, png.toString("base64"));

  if (drawn < 0.01) {
    throw new Error(`generated ${example} app canvas shows only its clear color (${(drawn * 100).toFixed(3)}% of pixels differ)`);
  }
  return drawn;
}

async function main() {
  const appRoot = mkdtempSync(join(tmpdir(), "three-rb-generated-app-"));
  const { chromium } = await loadPlaywright();
  let server;
  let browser;

  try {
    for (const example of examples) generate(appRoot, example);
    // --frozen-lockfile fails when the generated lockfile doesn't match the
    // generated package.json. The packages are already in the store from
    // this repository's install, so no download is needed.
    run("pnpm", ["install", "--frozen-lockfile", "--prefer-offline"], appRoot);

    server = await startServer(appRoot);
    browser = await chromium.launch({ headless: process.env.HEADLESS !== "0" });

    for (const example of examples) {
      const diagnostics = createDiagnostics();
      const page = await createSmokePage(browser, diagnostics);
      await page.goto(`${server.url}/examples/browser/${example}/`, { waitUntil: "load" });
      await waitForRunning(page, diagnostics);
      await page.waitForTimeout(500);
      const drawn = await assertCanvasRendered(page, example);
      assertNoDiagnostics(diagnostics);
      await page.close();
      console.log(`generated ${example} app smoke test passed (${(drawn * 100).toFixed(1)}% of the canvas drawn)`);
    }
  } finally {
    await browser?.close();
    if (server) await new Promise((resolve) => server.instance.close(resolve));
    rmSync(appRoot, { recursive: true, force: true });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
