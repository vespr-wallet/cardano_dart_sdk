// Patch script to make Squadron workers compatible with Chrome Extension Manifest V3
// Solution: Generate the loader by inlining the MJS runtime into the base loader template

const fs = require('fs');
const path = require('path');

const baseLoaderPath = path.join(__dirname, '../lib/workers/wallet_tasks.web.g.loader.base.js');
const loaderPath = path.join(__dirname, '../lib/workers/wallet_tasks.web.g.loader.js');
const mjsPath = path.join(__dirname, '../lib/workers/wallet_tasks.web.g.dart.mjs');

if (!fs.existsSync(baseLoaderPath)) {
  console.error('Base loader template not found at:', baseLoaderPath);
  process.exit(1);
}

if (!fs.existsSync(mjsPath)) {
  console.error('wallet_tasks.web.g.dart.mjs not found. Run flutter build first.');
  process.exit(1);
}

// Read the base loader template
let baseLoader = fs.readFileSync(baseLoaderPath, 'utf8');

// Read the MJS runtime code
let mjsContent = fs.readFileSync(mjsPath, 'utf8');

// Convert ES module exports to global object
// Replace all "export" statements with assignments to a global runtime object
mjsContent = mjsContent.replace(/export\s+(async\s+)?function\s+(\w+)/g, 'self.dart2wasm_runtime.$2 = $1function $2');
mjsContent = mjsContent.replace(/export\s+(const|let|var)\s+(\w+)/g, 'self.dart2wasm_runtime.$2');
mjsContent = mjsContent.replace(/export\s*\{[^}]+\}/g, ''); // Remove export {} statements

// Initialize the runtime object and inline the converted MJS code
const inlinedRuntime = `self.dart2wasm_runtime = {};\n${mjsContent}`;

// Replace the placeholder in the base loader with the inlined runtime
const finalLoader = baseLoader.replace('// RUNTIME_PLACEHOLDER - The patch script will inject the MJS runtime code here', inlinedRuntime);

// Write the generated loader
fs.writeFileSync(loaderPath, finalLoader, 'utf8');
console.log('✓ Generated wallet_tasks.web.g.loader.js from base template');
console.log('  - Inlined MJS runtime code (no ES module imports needed)');
console.log('  - Manifest V3 compatible');

// Also patch the generated Dart file to use the loader instead of the WASM file directly
const dartFilePath = path.join(__dirname, '../lib/workers/wallet_tasks.web.g.dart');
if (fs.existsSync(dartFilePath)) {
  let dartContent = fs.readFileSync(dartFilePath, 'utf8');

  // Replace the WASM entrypoint with the loader
  dartContent = dartContent.replace(
    /Squadron\.uri\(\s*'[^']*wallet_tasks\.web\.g\.dart\.wasm'\s*,?\s*\)/g,
    "Squadron.uri('/assets/packages/cardano_flutter_sdk/workers/wallet_tasks.web.g.loader.js'); // Modified for Manifest V3"
  );

  fs.writeFileSync(dartFilePath, dartContent, 'utf8');
  console.log('✓ Patched wallet_tasks.web.g.dart');
  console.log('  - Changed WASM worker to use custom loader');
}
