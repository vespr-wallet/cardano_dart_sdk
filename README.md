# Cardano Dart SDK for Flutter

[![Pub Version](https://img.shields.io/pub/v/cardano_flutter_sdk.svg)](https://pub.dev/packages/cardano_flutter_sdk)
[![GitHub Repo](https://img.shields.io/badge/github-vespr--wallet%2Fcardano__dart__sdk-blue?logo=github)](https://github.com/vespr-wallet/cardano_dart_sdk)

A high-level, cross-platform Dart SDK for Cardano wallet operations, targeting Flutter apps. This library enables parsing, address/key derivation, and transaction signing for Cardano, with a focus on security and performance. 

**Tested on:** Android, iOS, and Web. Should work on all Dart/Flutter platforms.

---

## Features

- BIP32-ED25519 HD wallet support (mnemonic/seed to keys/addresses)
- Cardano Shelley, Byron, and multi-era address support
- Transaction parsing, signing, and serialization
- Data signing (including dRep and committee credentials)
- Public key and address derivation (including xpub support)
- UTXO parsing and manipulation
- Web worker/wasm support for fast, non-blocking operations on web
- Built on top of [cardano_dart_types] for Cardano primitives
- Modern, null-safe Dart codebase

## Supported Standards
- [BIP-32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki) (HD wallets)
- [BIP-39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki) (mnemonic)
- [BIP-44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki) (multi-account)
- [CIP-3](https://cips.cardano.org/cips/cip3/) (key generation)
- [CIP-5](https://cips.cardano.org/cips/cip5/) (Bech32 prefixes)
- [CIP-1852](https://cips.cardano.org/cips/cip1852/) (wallet structure)
- [CIP-1855](https://cips.cardano.org/cips/cip1855/) (forging keys)
- [CIP-19](https://cips.cardano.org/cips/cip19/) (address structure)
- [CIP-105](https://github.com/cardano-foundation/CIPs/tree/master/CIP-0105) (Conway dRep/committee derivations)

---

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  cardano_flutter_sdk: ^2.5.1
  cardano_dart_types:
```

> **Note:** You must add a dependency to `cardano_dart_types` as well (do **not** specify a version; let pub resolve the compatible one).

---

## Platform Support

- **Android**: Fully supported
- **iOS**: Fully supported
- **Web**: Fully supported (uses web workers/wasm for performance)
- **Other Dart/Flutter platforms**: Should work, but not explicitly tested

---

## Quick Start

### 1. Create a Wallet from Mnemonic

```dart
import 'package:cardano_flutter_sdk/cardano_flutter_sdk.dart';
import 'package:cardano_dart_types/cardano_dart_types.dart';

void main() async {
  const mnemonic =
    'chief fiber betray curve tissue output feature jungle adapt smile brown crane accuse gospel plate unlock pull arrow hard february tape soccer patrol fetch';
  final wallet = await WalletFactory.fromMnemonic(NetworkId.mainnet, mnemonic.split(' '));

  final addrKit = await wallet.getPaymentAddressKit(addressIndex: 0);
  print('Address: \\${addrKit.address.bech32Encoded}');
  print('Stake Address: \\${wallet.stakeAddress.bech32Encoded}');
}
```

### 2. Sign a Transaction

```dart
import 'package:cardano_flutter_sdk/cardano_flutter_sdk.dart';
import 'package:cardano_dart_types/cardano_dart_types.dart';

void main() async {
  const mnemonic = 'chief fiber ... fetch';
  final wallet = await WalletFactory.fromMnemonic(NetworkId.testnet, mnemonic.split(' '));

  final txHex = '...'; // Your CBOR-encoded transaction hex
  final tx = CardanoTransaction.deserializeFromHex(txHex);

  final witnessSet = await wallet.signTransaction(
    tx: tx,
    witnessBech32Addresses: {'addr_test1...'},
  );

  final signedTx = tx.copyWithAdditionalSignatures(witnessSet);
  print(signedTx.serializeHexString());
}
```

### 3. Derive Addresses from xpub

```dart
import 'package:cardano_flutter_sdk/cardano_flutter_sdk.dart';
import 'package:cardano_dart_types/cardano_dart_types.dart';

void main() async {
  const xpub = 'xpub1...';
  final acc = await CardanoPubAccountWorkerFactory.instance.fromBech32XPub(xpub);
  print(await acc.stakeAddress(NetworkId.mainnet));
  for (var i = 0; i < 5; i++) {
    print(await acc.paymentBech32Address(i, NetworkId.mainnet));
    print(await acc.changeBech32Address(i, NetworkId.mainnet));
  }
}
```

---

## Example Projects

See the [`example/`](example/) directory for more usage examples:
- [wallet_example.dart](example/wallet_example.dart): Wallet creation, address derivation
- [sign_tx_example.dart](example/sign_tx_example.dart): Transaction signing
- [xpub_example.dart](example/xpub_example.dart): xpub address derivation
- [utxos_example.dart](example/utxos_example.dart): UTXO parsing
- [wallet_factory_example.dart](example/wallet_factory_example.dart): Mnemonic generation and batch wallet creation

---

## Contributing

Contributions, issues, and feature requests are welcome! See [issues](https://github.com/vespr-wallet/cardano_dart_sdk/issues).

---

## License

[MIT](LICENSE)

---

## Links
- [Pub.dev package](https://pub.dev/packages/cardano_flutter_sdk)
- [Cardano Dart Types](https://pub.dev/packages/cardano_dart_types)
- [Vespr Wallet](https://vespr.xyz)
- [Cardano CIPs](https://cips.cardano.org/)