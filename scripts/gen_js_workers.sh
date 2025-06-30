# Using 01 optimization level for better sentry error logs | 02 is also known to work
dart compile js lib/workers/wallet_tasks.web.g.dart -o lib/workers/wallet_tasks.web.g.dart.js -O1
dart compile wasm lib/workers/wallet_tasks.web.g.dart -o lib/workers/wallet_tasks.web.g.dart.wasm -O1