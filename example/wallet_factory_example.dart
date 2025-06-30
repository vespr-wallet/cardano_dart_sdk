import "dart:async";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/src/hd/wallet_factory.dart";

void main() async {
  var hasErr = false;
  loop:
  for (int i = 0; i < 200; i++) {
    if (hasErr) break loop;
    final mnem = WalletFactory.generateNewMnemonic();
    unawaited(
      WalletFactory.fromMnemonic(NetworkId.mainnet, mnem)
          .then((e) => print(e.firstAddress.bech32Encoded))
          .catchError((e) {
        hasErr = true;
        print(mnem);
        print(e);
      }),
    );
  }
}
