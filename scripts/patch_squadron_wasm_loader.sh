#!/bin/bash
# Patch script to make Squadron workers compatible with Chrome Extension Manifest V3
# Solution: Generate the loader by inlining the MJS runtime into the base loader template

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_LOADER_PATH="$SCRIPT_DIR/../web/wallet_tasks.web.g.loader.base.js"
LOADER_PATH="$SCRIPT_DIR/../lib/workers/wallet_tasks.web.g.loader.js"
MJS_PATH="$SCRIPT_DIR/../lib/workers/wallet_tasks.web.g.dart.mjs"
DART_FILE_PATH="$SCRIPT_DIR/../lib/workers/wallet_tasks.web.g.dart"
TEMP_RUNTIME="/tmp/squadron_runtime_$$.js"

# Check if base loader template exists
if [ ! -f "$BASE_LOADER_PATH" ]; then
  echo "Base loader template not found at: $BASE_LOADER_PATH"
  exit 1
fi

# Check if MJS runtime exists
if [ ! -f "$MJS_PATH" ]; then
  echo "wallet_tasks.web.g.dart.mjs not found. Run flutter build first."
  exit 1
fi

# Read and process the MJS runtime code
# Convert ES module exports to global object assignments
sed -E \
  -e 's/export[[:space:]]+(async[[:space:]]+)?function[[:space:]]+([a-zA-Z0-9_]+)/self.dart2wasm_runtime.\2 = \1function \2/g' \
  -e 's/export[[:space:]]+(const|let|var)[[:space:]]+([a-zA-Z0-9_]+)/self.dart2wasm_runtime.\2/g' \
  -e 's/export[[:space:]]*\{[^}]+\}//g' \
  "$MJS_PATH" > "$TEMP_RUNTIME"

# Create the final loader by replacing the placeholder
{
  while IFS= read -r line || [ -n "$line" ]; do
    if echo "$line" | grep -q '^// RUNTIME_PLACEHOLDER'; then
      echo "self.dart2wasm_runtime = {};"
      cat "$TEMP_RUNTIME"
    else
      printf '%s\n' "$line"
    fi
  done < "$BASE_LOADER_PATH"
} > "$LOADER_PATH"

# Clean up temp file
rm -f "$TEMP_RUNTIME"

echo "✓ Generated wallet_tasks.web.g.loader.js from base template"
echo "  - Inlined MJS runtime code (no ES module imports needed)"
echo "  - Manifest V3 compatible"

# Also patch the generated Dart file to use the loader instead of the WASM file directly
if [ -f "$DART_FILE_PATH" ]; then
  # Replace only the WASM path line, keeping exact formatting
  sed -i.bak "s|wallet_tasks\.web\.g\.dart\.wasm|wallet_tasks.web.g.loader.js|g" "$DART_FILE_PATH"
  rm -f "${DART_FILE_PATH}.bak"

  echo "✓ Patched wallet_tasks.web.g.dart"
  echo "  - Changed WASM worker to use custom loader"
fi
