import {
  assertNoDiagnostics,
  assertNonBlankCanvas,
  createDiagnostics,
  createSmokePage,
  loadPlaywright,
  sampleCanvas,
  startServer
} from "../../../examples/browser/shared/smoke_test_helpers.mjs";

async function main() {
  const { chromium } = await loadPlaywright();
  const server = await startServer();
  const browser = await chromium.launch({ headless: process.env.HEADLESS !== "0" });
  const diagnostics = createDiagnostics();

  try {
    const page = await createSmokePage(browser, diagnostics, { viewport: { width: 960, height: 720 } });

    await page.goto(`${server.url}/benchmarks/browser/instanced_mesh_sync/`, { waitUntil: "load" });
    await page.waitForFunction(() => Boolean(globalThis.__threeRbInstancedMeshSyncBenchmarkJson), null, { timeout: 180_000 });
    await page.waitForTimeout(500);

    assertNonBlankCanvas(await sampleCanvas(page));
    assertNoDiagnostics(diagnostics);

    const result = JSON.parse(await page.evaluate(() => globalThis.__threeRbInstancedMeshSyncBenchmarkJson));
    validateResult(result);
    console.log(JSON.stringify(result, null, 2));
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

function validateResult(result) {
  if (result.benchmark !== "browser_instanced_mesh_sync" || result.instance_count !== 1000 || result.iterations <= 0) {
    throw new Error(`unexpected benchmark metadata: ${JSON.stringify(result)}`);
  }

  for (const key of ["initial_sync_ms", "clean_sync", "dirty_object_transform_sync", "dirty_instance_matrix_sync", "backend_handle_count"]) {
    if (result[key] === undefined || result[key] === null) {
      throw new Error(`benchmark result is missing ${key}: ${JSON.stringify(result)}`);
    }
  }

  if (result.backend_handle_count < 5 || result.first_mesh_instanced !== true) {
    throw new Error(`benchmark did not materialize the expected scene graph: ${JSON.stringify(result)}`);
  }

  for (const section of [result.clean_sync, result.dirty_object_transform_sync, result.dirty_instance_matrix_sync]) {
    for (const key of ["min_ms", "max_ms", "avg_ms", "p95_ms"]) {
      if (typeof section[key] !== "number" || section[key] < 0) {
        throw new Error(`invalid benchmark timing: ${JSON.stringify(result)}`);
      }
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
