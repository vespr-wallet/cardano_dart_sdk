
// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredWasm` is a JS function that takes a module name matching a
  //   wasm file produced by the dart2wasm compiler and returns the bytes to
  //   load the module. These bytes can be in either a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  async instantiate(additionalImports, {loadDeferredWasm} = {}) {
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

      throw "Unable to print message: " + js;
    }

    // Converts a Dart List to a JS array. Any Dart objects will be converted, but
    // this will be cheap for JSValues.
    function arrayFromDartList(constructor, list) {
      const exports = dartInstance.exports;
      const read = exports.$listRead;
      const length = exports.$listLength(list);
      const array = new constructor(length);
      for (let i = 0; i < length; i++) {
        array[i] = read(list, i);
      }
      return array;
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

      _10: () => new Array(),
      _11: x0 => new Array(x0),
      _13: x0 => x0.length,
      _15: (x0,x1) => x0[x1],
      _16: (x0,x1,x2) => x0[x1] = x2,
      _19: (x0,x1,x2) => new DataView(x0,x1,x2),
      _21: x0 => new Int8Array(x0),
      _22: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _23: x0 => new Uint8Array(x0),
      _31: x0 => new Int32Array(x0),
      _33: x0 => new Uint32Array(x0),
      _35: x0 => new Float32Array(x0),
      _37: x0 => new Float64Array(x0),
      _38: (o, t) => typeof o === t,
      _39: (o, c) => o instanceof c,
      _43: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._43(f,arguments.length,x0) }),
      _44: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._44(f,arguments.length,x0) }),
      _67: (o) => !!o,
      _70: (decoder, codeUnits) => decoder.decode(codeUnits),
      _71: () => new TextDecoder("utf-8", {fatal: true}),
      _72: () => new TextDecoder("utf-8", {fatal: false}),
      _80: Date.now,
      _82: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _83: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _84: () => {
        let stackString = new Error().stack.toString();
        let frames = stackString.split('\n');
        let drop = 2;
        if (frames[0] === 'Error') {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _104: s => JSON.stringify(s),
      _105: s => printToConsole(s),
      _106: a => a.join(''),
      _109: (s, t) => s.split(t),
      _110: s => s.toLowerCase(),
      _111: s => s.toUpperCase(),
      _112: s => s.trim(),
      _116: (s, p, i) => s.indexOf(p, i),
      _117: (s, p, i) => s.lastIndexOf(p, i),
      _119: Object.is,
      _120: s => s.toUpperCase(),
      _121: s => s.toLowerCase(),
      _122: (a, i) => a.push(i),
      _129: (a, s) => a.join(s),
      _133: a => a.length,
      _135: (a, i) => a[i],
      _136: (a, i, v) => a[i] = v,
      _138: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _139: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _140: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _141: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _142: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _143: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _144: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _145: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _146: (o, start, length) => new BigUint64Array(o.buffer, o.byteOffset + start, length),
      _147: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _148: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _149: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _152: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _153: o => o.byteLength,
      _154: o => o.buffer,
      _155: o => o.byteOffset,
      _156: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _157: (b, o) => new DataView(b, o),
      _158: (b, o, l) => new DataView(b, o, l),
      _159: Function.prototype.call.bind(DataView.prototype.getUint8),
      _160: Function.prototype.call.bind(DataView.prototype.setUint8),
      _161: Function.prototype.call.bind(DataView.prototype.getInt8),
      _162: Function.prototype.call.bind(DataView.prototype.setInt8),
      _163: Function.prototype.call.bind(DataView.prototype.getUint16),
      _164: Function.prototype.call.bind(DataView.prototype.setUint16),
      _165: Function.prototype.call.bind(DataView.prototype.getInt16),
      _166: Function.prototype.call.bind(DataView.prototype.setInt16),
      _167: Function.prototype.call.bind(DataView.prototype.getUint32),
      _168: Function.prototype.call.bind(DataView.prototype.setUint32),
      _169: Function.prototype.call.bind(DataView.prototype.getInt32),
      _170: Function.prototype.call.bind(DataView.prototype.setInt32),
      _171: Function.prototype.call.bind(DataView.prototype.getBigUint64),
      _172: Function.prototype.call.bind(DataView.prototype.setBigUint64),
      _173: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _174: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _175: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _177: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _195: o => Object.keys(o),
      _196: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _200: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _220: (x0,x1) => globalThis.fetch(x0,x1),
      _222: (x0,x1,x2) => x0.postMessage(x1,x2),
      _225: (x0,x1) => x0.push(x1),
      _226: x0 => x0.close(),
      _227: x0 => x0.close(),
      _228: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._228(f,arguments.length,x0) }),
      _229: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._229(f,arguments.length,x0) }),
      _230: x0 => x0.close(),
      _231: x0 => x0.close(),
      _232: () => new MessageChannel(),
      _234: () => new MessageChannel(),
      _235: x0 => new Worker(x0),
      _236: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._236(f,arguments.length,x0) }),
      _237: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._237(f,arguments.length,x0) }),
      _238: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._238(f,arguments.length,x0) }),
      _239: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._239(f,arguments.length,x0) }),
      _240: (x0,x1,x2) => x0.postMessage(x1,x2),
      _241: x0 => x0.close(),
      _242: x0 => x0.close(),
      _243: x0 => x0.terminate(),
      _249: () => globalThis.self,
      _250: () => new MessageChannel(),
      _251: x0 => x0.close(),
      _252: x0 => x0.close(),
      _253: x0 => x0.close(),
      _254: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._254(f,arguments.length,x0) }),
      _255: f => finalizeWrapper(f, function(x0) { return dartInstance.exports._255(f,arguments.length,x0) }),
      _256: (x0,x1,x2) => x0.postMessage(x1,x2),
      _257: (x0,x1) => x0.postMessage(x1),
      _258: x0 => globalThis.URL.revokeObjectURL(x0),
      _259: x0 => ({type: x0}),
      _260: (x0,x1) => new Blob(x0,x1),
      _261: x0 => globalThis.URL.createObjectURL(x0),
      _262: (x0,x1) => x0.push(x1),
      _263: (x0,x1) => x0.push(x1),
      _269: (x0,x1) => x0.push(x1),
      _270: () => new Map(),
      _271: (x0,x1,x2) => x0.set(x1,x2),
      _272: () => new Set(),
      _273: (x0,x1) => x0.add(x1),
      _274: x0 => globalThis.BigInt(x0),
      _275: (x0,x1) => x0.at(x1),
      _276: x0 => x0.entries(),
      _277: (x0,x1) => x0.at(x1),
      _278: (x0,x1) => x0.at(x1),
      _279: x0 => x0.values(),
      _280: x0 => x0.toString(),
      _283: x0 => x0.length,
      _295: x0 => x0.buffer,
      _311: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _312: (x0,x1) => x0.exec(x1),
      _313: (x0,x1) => x0.test(x1),
      _314: (x0,x1) => x0.exec(x1),
      _315: (x0,x1) => x0.exec(x1),
      _316: x0 => x0.pop(),
      _318: o => o === undefined,
      _337: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _339: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _340: o => o instanceof RegExp,
      _341: (l, r) => l === r,
      _342: o => o,
      _343: o => o,
      _344: o => o,
      _345: b => !!b,
      _346: o => o.length,
      _349: (o, i) => o[i],
      _350: f => f.dartFunction,
      _351: l => arrayFromDartList(Int8Array, l),
      _352: l => arrayFromDartList(Uint8Array, l),
      _353: l => arrayFromDartList(Uint8ClampedArray, l),
      _354: l => arrayFromDartList(Int16Array, l),
      _355: l => arrayFromDartList(Uint16Array, l),
      _356: l => arrayFromDartList(Int32Array, l),
      _357: l => arrayFromDartList(Uint32Array, l),
      _358: l => arrayFromDartList(Float32Array, l),
      _359: l => arrayFromDartList(Float64Array, l),
      _360: x0 => new ArrayBuffer(x0),
      _361: (data, length) => {
        const getValue = dartInstance.exports.$byteDataGetUint8;
        const view = new DataView(new ArrayBuffer(length));
        for (let i = 0; i < length; i++) {
          view.setUint8(i, getValue(data, i));
        }
        return view;
      },
      _362: l => arrayFromDartList(Array, l),
      _363: () => ({}),
      _364: () => [],
      _365: l => new Array(l),
      _366: () => globalThis,
      _369: (o, p) => o[p],
      _370: (o, p, v) => o[p] = v,
      _371: (o, m, a) => o[m].apply(o, a),
      _373: o => String(o),
      _374: (p, s, f) => p.then(s, f),
      _375: o => {
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
        return 17;
      },
      _376: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _377: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _380: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _382: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _384: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _389: x0 => x0.index,
      _394: x0 => x0.flags,
      _395: x0 => x0.multiline,
      _396: x0 => x0.ignoreCase,
      _397: x0 => x0.unicode,
      _398: x0 => x0.dotAll,
      _399: (x0,x1) => x0.lastIndex = x1,
      _401: (o, p) => o[p],
      _404: x0 => x0.random(),
      _405: x0 => x0.random(),
      _409: () => globalThis.Math,
      _411: Function.prototype.call.bind(Number.prototype.toString),
      _412: (d, digits) => d.toFixed(digits),
      _2286: () => globalThis.window,
      _2333: x0 => x0.location,
      _2635: x0 => x0.pathname,
      _2677: x0 => x0.filename,
      _2678: x0 => x0.lineno,
      _2825: x0 => x0.port1,
      _2826: x0 => x0.port2,
      _2832: (x0,x1) => x0.onmessage = x1,
      _2834: (x0,x1) => x0.onmessageerror = x1,
      _2894: (x0,x1) => x0.onmessage = x1,
      _2906: (x0,x1) => x0.onmessage = x1,
      _2908: (x0,x1) => x0.onmessageerror = x1,
      _2910: (x0,x1) => x0.onerror = x1,
      _7617: x0 => x0.status,
      _7618: x0 => x0.ok,

    };

    const baseImports = {
      dart2wasm: dart2wasm,


      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
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
    };

    const deferredLibraryHelper = {
      "loadModule": async (moduleName) => {
        if (!loadDeferredWasm) {
          throw "No implementation of loadDeferredWasm provided.";
        }
        const source = await Promise.resolve(loadDeferredWasm(moduleName));
        const module = await ((source instanceof Response)
            ? WebAssembly.compileStreaming(source, this.builtins)
            : WebAssembly.compile(source, this.builtins));
        return await WebAssembly.instantiate(module, {
          ...baseImports,
          ...additionalImports,
          "wasm:js-string": jsStringPolyfill,
          "module0": dartInstance.exports,
        });
      },
    };

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      "deferredLibraryHelper": deferredLibraryHelper,
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

