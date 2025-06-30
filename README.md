# SDK For Cardano using Flutter

## ~~Compatibility for web~~

### BELOW SHOULD NOT BE NEEDED ANYMORE

In your project, open `web/index.html` and add the following inside the `<head>` tag:

```html
    <script
      type="application/javascript"
      src="/assets/packages/cardano_flutter_sdk/workers/wallet_tasks.web.g.dart.js"
      defer
    ></script>
    <script
      type="application/javascript"
      src="/assets/packages/cardano_flutter_sdk/workers/wallet_tasks.web.g.dart.mjs"
      defer
    ></script>
    <script
      type="application/javascript"
      src="/assets/packages/cardano_flutter_sdk/workers/wallet_tasks.web.g.dart.wasm"
      defer
    ></script>
```