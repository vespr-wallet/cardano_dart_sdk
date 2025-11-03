// Base loader template for Squadron WASM workers in Chrome Extension Manifest V3
// The dart2wasm runtime will be inlined here by the patch script

// RUNTIME_PLACEHOLDER - The patch script will inject the MJS runtime code here

console.log('[WASM Loader] Starting Squadron WASM worker loader...');

// Global error handlers for the worker
self.addEventListener('error', (event) => {
  console.error('[WASM Loader] Uncaught error in worker:', event.error, event);
  const ts = (Date.now() - Date.UTC(2020, 1, 2)) * 1000;
  postMessage([
    ts,
    null,
    [
      "$!",
      `Uncaught error in worker: ${event.error?.message || event.message}`,
      event.error?.stack || null,
      null,
    ],
    null,
    null,
  ]);
});

self.addEventListener('unhandledrejection', (event) => {
  console.error('[WASM Loader] Unhandled promise rejection in worker:', event.reason);
  const ts = (Date.now() - Date.UTC(2020, 1, 2)) * 1000;
  postMessage([
    ts,
    null,
    [
      "$!",
      `Unhandled rejection: ${event.reason?.message || event.reason}`,
      event.reason?.stack || null,
      null,
    ],
    null,
    null,
  ]);
});

(async function () {
    const url = "/assets/packages/cardano_flutter_sdk/workers/wallet_tasks.web.g.dart.wasm";
    console.log('[WASM Loader] Loading WASM from:', url);

    const workerUri = new URL(url.replaceAll('"', '\\"'), self.location.origin).href;
    console.log('[WASM Loader] Resolved worker URI:', workerUri);

    try {
      let moduleInstance;
      try {
        console.log('[WASM Loader] Fetching WASM module...');
        const response = await fetch(workerUri);
        console.log('[WASM Loader] Fetch response status:', response.status, response.statusText);

        if (!response.ok) {
          throw new Error(`Failed to fetch WASM: ${response.status} ${response.statusText}`);
        }

        console.log('[WASM Loader] Compiling WASM module...');
        const dartModule = WebAssembly.compileStreaming(response);

        console.log('[WASM Loader] Instantiating WASM module...');
        moduleInstance = await self.dart2wasm_runtime.instantiate(dartModule, {});
        console.log('[WASM Loader] WASM module instantiated successfully');
      } catch (exception) {
        console.error(
          `[WASM Loader] Failed to fetch and instantiate wasm module ${workerUri}:`,
          exception
        );
        console.error('[WASM Loader] Exception stack:', exception.stack);
        console.error('[WASM Loader] See https://dart.dev/web/wasm for more information.');
        throw new Error(
          exception.message ?? "Unknown error when instantiating worker module",
        );
      }
      try {
        console.log('[WASM Loader] Invoking WASM module main...');
        await self.dart2wasm_runtime.invoke(moduleInstance);
        console.log('[WASM Loader] Successfully loaded and invoked', workerUri);
      } catch (exception) {
        console.error(
          `[WASM Loader] Exception while invoking wasm module ${workerUri}:`,
          exception
        );
        console.error('[WASM Loader] Exception stack:', exception.stack);
        throw new Error(
          exception.message ?? "Unknown error when invoking worker module",
        );
      }
    } catch (ex) {
      console.error('[WASM Loader] Fatal error in loader:', ex);
      console.error('[WASM Loader] Error stack:', ex.stack);
      const ts = (Date.now() - Date.UTC(2020, 1, 2)) * 1000;
      postMessage([
        ts,
        null,
        [
          "$!",
          `Failed to load Web Worker from ${workerUri}: ${ex.message || ex}`,
          ex.stack || null,
          null,
        ],
        null,
        null,
      ]);
    }
  })();
  