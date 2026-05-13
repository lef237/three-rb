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

    await page.goto(`${server.url}/examples/browser/gltf/`, { waitUntil: "load" });
    await waitForRunning(page, diagnostics);
    await page.waitForFunction(
      () => globalThis.__threeRbGltfScene?.children?.length > 0,
      null,
      { timeout: 10_000 }
    );
    await page.waitForTimeout(1_000);

    assertNonBlankCanvas(await sampleCanvas(page));

    const scene = await page.evaluate(() => ({
      frame: globalThis.__threeRbGltfFrame,
      animationTime: globalThis.__threeRbGltfAnimationTime,
      animationCount: globalThis.__threeRbGltfAnimations,
      animationName: globalThis.__threeRbGltfAnimationName,
      animationDuration: globalThis.__threeRbGltfAnimationDuration,
      actionTime: globalThis.__threeRbGltfAction?.time,
      animatedNodeQuaternion: globalThis.__threeRbGltfScene?.children?.[0]?.quaternion?.toArray?.(),
      renderInfo: globalThis.__threeRbRenderer?.info?.render,
      cameraType: globalThis.__threeRbCamera?.type,
      rootChildren: globalThis.__threeRbGltfRootScene?.children?.length,
      gltfType: globalThis.__threeRbGltfScene?.type,
      gltfIsObject3D: globalThis.__threeRbGltfScene?.isObject3D,
      gltfChildren: globalThis.__threeRbGltfScene?.children?.length
    }));

    if (scene.cameraType !== "PerspectiveCamera") {
      throw new Error(`expected a PerspectiveCamera glTF view: ${JSON.stringify(scene)}`);
    }
    if (scene.gltfIsObject3D !== true || scene.gltfChildren < 1) {
      throw new Error(`expected a loaded glTF Object3D scene: ${JSON.stringify(scene)}`);
    }
    if (!scene.renderInfo || scene.renderInfo.triangles < 1) {
      throw new Error(`renderer did not draw the glTF triangle: ${JSON.stringify(scene)}`);
    }
    if (!scene.frame) {
      throw new Error(`glTF example animation did not advance: ${JSON.stringify(scene)}`);
    }
    if (scene.animationCount !== 1 || scene.animationName !== "TriangleSpin" || scene.animationDuration !== 2) {
      throw new Error(`glTF animation metadata was not exposed: ${JSON.stringify(scene)}`);
    }
    if (!(scene.animationTime > 0) || !(scene.actionTime > 0)) {
      throw new Error(`AnimationMixer did not advance the glTF action: ${JSON.stringify(scene)}`);
    }
    if (!scene.animatedNodeQuaternion || Math.abs(scene.animatedNodeQuaternion[1]) < 0.05) {
      throw new Error(`glTF animated node quaternion did not change: ${JSON.stringify(scene)}`);
    }

    const disposal = await page.evaluate(() => {
      const root = globalThis.__threeRbGltfScene;
      const rootScene = globalThis.__threeRbGltfRootScene;
      const stats = {
        geometries: 0,
        materials: 0,
        textures: 0,
        geometryDisposeEvents: 0,
        materialDisposeEvents: 0,
        textureDisposeEvents: 0
      };

      root.traverse((object) => {
        if (object.geometry) {
          stats.geometries += 1;
          object.geometry.addEventListener("dispose", () => {
            stats.geometryDisposeEvents += 1;
          });
        }

        const materials = Array.isArray(object.material) ? object.material : [object.material].filter(Boolean);
        for (const material of materials) {
          stats.materials += 1;
          material.addEventListener("dispose", () => {
            stats.materialDisposeEvents += 1;
          });

          if (material.map) {
            stats.textures += 1;
            material.map.addEventListener("dispose", () => {
              stats.textureDisposeEvents += 1;
            });
          }
        }
      });

      globalThis.__threeRbDisposeGltf();

      return {
        ...stats,
        disposed: globalThis.__threeRbGltfDisposed,
        rootParent: root.parent?.type ?? null,
        rootSceneStillContainsRoot: rootScene.children.includes(root)
      };
    });

    if (disposal.disposed !== true || disposal.rootParent !== null || disposal.rootSceneStillContainsRoot) {
      throw new Error(`dispose_subtree did not detach the glTF root: ${JSON.stringify(disposal)}`);
    }
    if (disposal.geometries < 1 || disposal.geometryDisposeEvents !== disposal.geometries) {
      throw new Error(`dispose_subtree did not dispose loaded geometries: ${JSON.stringify(disposal)}`);
    }
    if (disposal.materials < 1 || disposal.materialDisposeEvents !== disposal.materials) {
      throw new Error(`dispose_subtree did not dispose loaded materials: ${JSON.stringify(disposal)}`);
    }
    if (disposal.textureDisposeEvents !== disposal.textures) {
      throw new Error(`dispose_subtree did not dispose loaded textures: ${JSON.stringify(disposal)}`);
    }

    assertNoDiagnostics(diagnostics);

    console.log(`glTF smoke test passed at ${server.url}/examples/browser/gltf/`);
  } finally {
    await browser.close();
    await new Promise((resolve) => server.instance.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
