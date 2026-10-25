// Base loader template for Squadron WASM workers in Chrome Extension Manifest V3
// The dart2wasm runtime will be inlined here by the patch script

self.dart2wasm_runtime = {};
// Compiles a dart2wasm-generated main module from `source` which can then
// be instantiated via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
self.dart2wasm_runtime.compileStreaming = async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm module from `bytes` which is then
// instantiable via the `instantiate` method.
self.dart2wasm_runtime.compile = async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arguments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `use-load-ids` option is passed. Each load ID maps to
  //   one or more wasm files as specified in the emitted JSON file. It also
  //   takes a callback that should be invoked for each loaded module with 2
  //   arguments: (1) the module name, (2) the loaded module in a format
  //   supported by `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  //   The callback returns a Promise that resolves when the module is
  //   instantiated.
  //   loadDeferredId should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports, {loadDeferredModules, loadDeferredId} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            AB: (b, o) => new DataView(b, o),
      AC: (l, r) => l === r,
      AD: (o, i) => o[i],
      B: s => printToConsole(s),
      BB: (b, o, l) => new DataView(b, o, l),
      BC: (x0,x1) => globalThis.Object.is(x0,x1),
      BD: o => o.length,
      C: Function.prototype.call.bind(Number.prototype.toString),
      CB: Function.prototype.call.bind(DataView.prototype.getFloat64),
      CC: o => o,
      CD: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      D: Function.prototype.call.bind(BigInt.prototype.toString),
      DB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      DC: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      DD: (x0,x1) => x0.at(x1),
      E: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      EB: Function.prototype.call.bind(DataView.prototype.setFloat64),
      EC: s => new Date(s * 1000).getTimezoneOffset() * 60,
      ED: x0 => x0.entries(),
      F: () => new Error().stack,
      FB: (t, s) => t.set(s),
      FC: Date.now,
      FD: x0 => x0.values(),
      G: s => JSON.stringify(s),
      GB: Function.prototype.call.bind(DataView.prototype.setFloat32),
      GC: (x0,x1) => { x0.onmessage = x1 },
      GD: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      H: Function.prototype.call.bind(Number.prototype.toString),
      HB: Function.prototype.call.bind(DataView.prototype.getFloat32),
      HC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      HD: o => Object.keys(o),
      I: Function.prototype.call.bind(String.prototype.indexOf),
      IB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      IC: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      ID: (o) => !!o,
      J: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      JB: Function.prototype.call.bind(DataView.prototype.getUint32),
      JC: x0 => x0.close(),
      JD: (o, m, a) => o[m].apply(o, a),
      K: o => o === undefined,
      KB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      KC: x0 => x0.close(),
      KD: x0 => x0.length,
      L: o => String(o),
      LB: Function.prototype.call.bind(DataView.prototype.getInt32),
      LC: (x0,x1) => x0.postMessage(x1),
      LD: x0 => x0.toString(),
      M: () => new MessageChannel(),
      MB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      MC: (s, p, i) => s.lastIndexOf(p, i),
      MD: x0 => x0.getTime(),
      N: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      NB: o => o instanceof Uint16Array,
      NC: (a, s) => a.join(s),
      ND: (x0,x1) => x0[x1],
      O: () => new Array(),
      OB: Function.prototype.call.bind(DataView.prototype.getUint16),
      OC: (x0,x1,x2) => x0.postMessage(x1,x2),
      OD: x0 => x0.length,
      P: (x0,x1,x2) => x0.postMessage(x1,x2),
      PB: o => o instanceof Int16Array,
      PC: (a, i, v) => a[i] = v,
      PD: (x0,x1) => x0.exec(x1),
      Q: (x0,x1) => x0.push(x1),
      QB: Function.prototype.call.bind(DataView.prototype.getInt16),
      QC: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      QD: x0 => x0.flags,
      R: () => new Map(),
      RB: o => o instanceof Uint8ClampedArray,
      RC: s => s.toUpperCase(),
      RD: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      S: (x0,x1,x2) => x0.set(x1,x2),
      SB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      SC: Object.is,
      SD: o => o instanceof RegExp,
      T: () => new Set(),
      TB: Function.prototype.call.bind(DataView.prototype.setInt32),
      TC: (string, times) => string.repeat(times),
      TD: (o, t) => typeof o === t,
      U: (x0,x1) => x0.add(x1),
      UB: Function.prototype.call.bind(DataView.prototype.setUint32),
      UC: (s) => +s,
      UD: x0 => ({type: x0}),
      V: () => ({}),
      VB: Function.prototype.call.bind(DataView.prototype.setInt16),
      VC: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      VD: (x0,x1) => new Blob(x0,x1),
      W: (o, p, v) => o[p] = v,
      WB: Function.prototype.call.bind(DataView.prototype.setUint16),
      WC: s => s.trim(),
      WD: x0 => globalThis.URL.createObjectURL(x0),
      X: () => [],
      XB: Function.prototype.call.bind(DataView.prototype.setUint8),
      XC: (decoder, codeUnits) => decoder.decode(codeUnits),
      XD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      Y: (a, i) => a.push(i),
      YB: Function.prototype.call.bind(DataView.prototype.setInt8),
      YC: () => new TextDecoder("utf-8", {fatal: true}),
      YD: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      Z: x0 => x0.random(),
      ZB: Function.prototype.call.bind(DataView.prototype.getInt8),
      ZC: () => new TextDecoder("utf-8", {fatal: false}),
      ZD: (x0,x1) => { x0.onmessageerror = x1 },
      a: o => o,
      aB: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      aC: (o, p, r) => o.replaceAll(p, () => r),
      aD: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      b: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      bB: o => o,
      bC: Function.prototype.call.bind(String.prototype.toLowerCase),
      bD: x0 => x0.pathname,
      c: () => globalThis.Math,
      cB: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      cC: () => typeof dartUseDateNowForTicks !== "undefined",
      cD: x0 => x0.location,
      d: b => !!b,
      dB: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      dC: () => Date.now(),
      dD: () => globalThis.window,
      e: x0 => new Int8Array(x0),
      eB: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      eC: () => 1000 * performance.now(),
      eD: x0 => x0.pop(),
      f: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      fB: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      fC: x0 => new Worker(x0),
      fD: (x0,x1) => { x0.lastIndex = x1 },
      g: x0 => new Uint8Array(x0),
      gB: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      gC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      gD: x0 => x0.dotAll,
      h: x0 => new Uint8ClampedArray(x0),
      hB: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      hC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      hD: x0 => x0.unicode,
      i: x0 => new Int16Array(x0),
      iB: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      iC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      iD: x0 => x0.ignoreCase,
      j: x0 => new Uint16Array(x0),
      jB: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      jC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      jD: x0 => x0.multiline,
      k: x0 => new Int32Array(x0),
      kB: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      kC: (x0,x1,x2) => x0.postMessage(x1,x2),
      kD: x0 => x0.index,
      l: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      lB: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      lC: x0 => x0.terminate(),
      lD: (o, p, r) => o.replace(p, () => r),
      m: x0 => new Uint32Array(x0),
      mB: o => [o],
      mC: x0 => globalThis.URL.revokeObjectURL(x0),
      mD: (d, digits) => d.toFixed(digits),
      n: x0 => new Float32Array(x0),
      nB: (o0, o1) => [o0, o1],
      nC: (x0,x1) => { x0.onmessage = x1 },
      nD: x0 => x0.port2,
      o: x0 => new Float64Array(x0),
      oB: (o0, o1, o2) => [o0, o1, o2],
      oC: (x0,x1) => { x0.onmessageerror = x1 },
      oD: (x0,x1) => { x0.onmessage = x1 },
      p: x0 => new ArrayBuffer(x0),
      pB: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      pC: (x0,x1) => { x0.onerror = x1 },
      pD: x0 => x0.port1,
      q: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      qB: (o, p) => o[p],
      qC: x0 => x0.lineno,
      qD: () => globalThis.self,
      r: (x0,x1,x2) => new DataView(x0,x1,x2),
      rB: () => globalThis,
      rC: x0 => x0.filename,
      s: (o, p) => o[p],
      sB: x0 => globalThis.BigInt(x0),
      sC: (x0,x1) => globalThis.fetch(x0,x1),
      t: x0 => new Array(x0),
      tB: (o, c) => o instanceof c,
      tC: x0 => x0.status,
      u: (x0,x1,x2) => { x0[x1] = x2 },
      uB: (string, token) => string.split(token),
      uC: x0 => x0.ok,
      v: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      vB: o => o instanceof Array,
      vC: (wasmFunction,f) => finalizeWrapper(f, function(x0) { return wasmFunction(f,arguments.length,x0) }),
      w: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      wB: (a, i) => a[i],
      wC: (wasmFunction,f) => finalizeWrapper(f, function(x0,x1) { return wasmFunction(f,arguments.length,x0,x1) }),
      x: o => o.byteOffset,
      xB: a => a.length,
      xC: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      y: o => o.buffer,
      yB: x0 => x0.buffer,
      yC: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      z: Function.prototype.call.bind(DataView.prototype.getUint8),
      zB: (o) => {
        return o instanceof Object.getPrototypeOf(Int8Array);
      },
      zC: f => f.dartFunction,

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      WebAssembly: {
        JSTag: WebAssembly.JSTag,
      },
      "": new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}

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
      let instantiatedApp;
      try {
        logger.log('[WASM Loader] Fetching WASM module...');
        const response = await fetch(workerUri);
        logger.log('[WASM Loader] Fetch response status:', response.status, response.statusText);

        if (!response.ok) {
          throw new Error(`Failed to fetch WASM: ${response.status} ${response.statusText}`);
        }

        logger.log('[WASM Loader] Compiling and instantiating WASM module...');
        // Use compileStreaming (not raw WebAssembly.compileStreaming) so the
        // dart2wasm runtime includes the required {builtins: ['js-string']} option.
        const compiledApp = await self.dart2wasm_runtime.compileStreaming(response);
        // instantiate() also calls $setThisModule — required since dart2wasm 3.11.
        instantiatedApp = await compiledApp.instantiate({});
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
        instantiatedApp.invokeMain();
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
  
