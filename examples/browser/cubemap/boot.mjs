import { bootRubyExample } from "../shared/boot.mjs";

await bootRubyExample({
  main: "examples/browser/cubemap/main",
  clearColor: 0x10151b
});
