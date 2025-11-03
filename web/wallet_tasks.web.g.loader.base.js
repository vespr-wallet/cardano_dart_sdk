// Base loader template for Squadron WASM workers in Chrome Extension Manifest V3
// The dart2wasm runtime will be inlined here by the patch script

// RUNTIME_PLACEHOLDER - The patch script will inject the MJS runtime code here

(async function () {
    const url = "lib/workers/wallet_tasks.web.g.dart.wasm";
    const workerUri = new URL(url.replaceAll('"', '\\"'), self.location.origin).href;
  
    try {
      let moduleInstance;
      try {
        const dartModule = WebAssembly.compileStreaming(fetch(workerUri));
        moduleInstance = await self.dart2wasm_runtime.instantiate(dartModule, {});
      } catch (exception) {
        console.error(
          `Failed to fetch and instantiate wasm module ${workerUri}: ${exception}`,
        );
        console.error("See https://dart.dev/web/wasm for more information.");
        throw new Error(
          exception.message ?? "Unknown error when instantiating worker module",
        );
      }
      try {
        await self.dart2wasm_runtime.invoke(moduleInstance);
        //console.log(`Succesfully loaded and invoked ${workerUri}`);
      } catch (exception) {
        console.error(
          `Exception while invoking wasm module ${workerUri}: ${exception}`,
        );
        throw new Error(
          exception.message ?? "Unknown error when invoking worker module",
        );
      }
    } catch (ex) {
      const ts = (Date.now() - Date.UTC(2020, 1, 2)) * 1000;
      postMessage([
        ts,
        null,
        [
          "$!",
          `Failed to load Web Worker from ${workerUri}: ${ex}`,
          null,
          null,
        ],
        null,
        null,
      ]);
    }
  })();
  