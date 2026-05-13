# 1000 Individual Mesh Sync Benchmark

This browser benchmark measures Ruby-to-three.js scene synchronization for a scene with 1000 individual `Three::Mesh` objects sharing one geometry and one material.

It is intentionally not part of the default test suite because performance numbers vary by machine and browser runtime. Run it manually when changing scene graph traversal, transform dirty tracking, or backend sync behavior.

```sh
pnpm benchmark:browser:mesh-sync
```

The output reports:

- initial sync time for first materialization
- clean sync time after no object changes
- dirty transform sync time after updating every mesh transform
- backend handle count

Use this benchmark to decide whether normal `Mesh` synchronization needs additional batching. Repeated geometry should still prefer `Three::InstancedMesh`.

The sync layer should skip clean child subtrees. If clean sync time regresses toward dirty transform sync time, check `Object3D` descendant dirty tracking and resource dirty propagation first.
