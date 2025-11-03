// Base loader template for Squadron WASM workers in Chrome Extension Manifest V3
// The dart2wasm runtime will be inlined here by the patch script

// RUNTIME_PLACEHOLDER - The patch script will inject the MJS runtime code here

// No-op logger by default to prevent sensitive data leakage
// Set to console to enable logging for debugging
//
// const logger = console;
const logger = { 
  log: () => {},
  error: () => {}
};

// Global error handlers for the worker
self.addEventListener('error', (event) => {
  logger.error('[WASM Loader] Uncaught error in worker:', event.error, event);
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
  logger.error('[WASM Loader] Unhandled promise rejection in worker:', event.reason);
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
    logger.log('[WASM Loader] Loading WASM from:', url);

    const workerUri = new URL(url.replaceAll('"', '\\"'), self.location.origin).href;
    logger.log('[WASM Loader] Resolved worker URI:', workerUri);

    try {
      let moduleInstance;
      try {
        logger.log('[WASM Loader] Fetching WASM module...');
        const response = await fetch(workerUri);
        logger.log('[WASM Loader] Fetch response status:', response.status, response.statusText);

        if (!response.ok) {
          throw new Error(`Failed to fetch WASM: ${response.status} ${response.statusText}`);
        }

        logger.log('[WASM Loader] Compiling WASM module...');
        const dartModule = WebAssembly.compileStreaming(response);

        logger.log('[WASM Loader] Instantiating WASM module...');
        moduleInstance = await self.dart2wasm_runtime.instantiate(dartModule, {});
        logger.log('[WASM Loader] WASM module instantiated successfully');
      } catch (exception) {
        logger.error(
          `[WASM Loader] Failed to fetch and instantiate wasm module ${workerUri}:`,
          exception
        );
        logger.error('[WASM Loader] Exception stack:', exception.stack);
        logger.error('[WASM Loader] See https://dart.dev/web/wasm for more information.');
        throw new Error(
          exception.message ?? "Unknown error when instantiating worker module",
        );
      }
      try {
        logger.log('[WASM Loader] Invoking WASM module main...');
        await self.dart2wasm_runtime.invoke(moduleInstance);
        logger.log('[WASM Loader] Successfully loaded and invoked', workerUri);
      } catch (exception) {
        logger.error(
          `[WASM Loader] Exception while invoking wasm module ${workerUri}:`,
          exception
        );
        logger.error('[WASM Loader] Exception stack:', exception.stack);
        throw new Error(
          exception.message ?? "Unknown error when invoking worker module",
        );
      }
    } catch (ex) {
      logger.error('[WASM Loader] Fatal error in loader:', ex);
      logger.error('[WASM Loader] Error stack:', ex.stack);
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
  