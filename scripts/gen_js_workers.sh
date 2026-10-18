set -e

# Point the wasm activator at the MV3 loader BEFORE compiling: the workers start nested workers (the pools in
# wallet_tasks.dart) with the activator compiled into them. A `.wasm` entry makes Squadron spawn a blob worker that
# import()s the `.mjs`, which Chrome 155+ blocks in extensions (CSP). build_runner regenerates the `.wasm` entry.
sed -i.bak "s|wallet_tasks\.web\.g\.dart\.wasm|wallet_tasks.web.g.loader.js|g" lib/workers/wallet_tasks.web.g.dart
rm -f lib/workers/wallet_tasks.web.g.dart.bak

# Using 01 optimization level for better sentry error logs | 02 is also known to work
dart compile js lib/workers/wallet_tasks.web.g.dart -o lib/workers/wallet_tasks.web.g.dart.js -O1
dart compile wasm lib/workers/wallet_tasks.web.g.dart -o lib/workers/wallet_tasks.web.g.dart.wasm -O1
sh scripts/patch_squadron_wasm_loader.sh

# Fail if the compiled wasm worker would not start its nested workers through the loader.
if ! grep -q "wallet_tasks.web.g.loader.js" lib/workers/wallet_tasks.web.g.dart.wasm; then
  echo "wallet_tasks.web.g.dart.wasm does not use the MV3 loader for nested workers" >&2
  exit 1
fi
