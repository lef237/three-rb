# 1000 InstancedMesh Sync Benchmark

This browser benchmark measures Ruby-to-three.js scene synchronization for a scene with one `Three::InstancedMesh` rendering 1000 instances.

It is intentionally not part of the default test suite because performance numbers vary by machine and browser runtime. Run it manually when changing scene graph traversal, transform dirty tracking, or backend sync behavior.

```sh
pnpm benchmark:browser:instanced-mesh-sync
```

The output reports:

- initial sync time for first materialization
- clean sync time after no object changes
- dirty object transform sync time after moving the single `InstancedMesh`
- dirty instance matrix sync time after updating every instance matrix
- backend handle count

Use this benchmark as the baseline for repeated geometry. Whole-field animation should stay cheap because it only syncs one `Object3D` transform. Per-instance animation still crosses the Ruby-to-JavaScript boundary once per updated instance, so compare that section with the individual Mesh benchmark before optimizing the backend.

The sync layer should skip clean child subtrees. If clean sync time regresses toward dirty instance sync time, check `Object3D` descendant dirty tracking and resource dirty propagation first.
