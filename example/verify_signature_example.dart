// ignore_for_file: avoid_print

import "package:bip32_ed25519/api.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";


const addressCount = 50;

Future<void> deriveFromXPub() async {
  final xpub =
      "17409bf58f590d559973fdadb5fad523f20e1fdd9d81ef99700e5ad48209f85340ae2e846f886e8b131d8ec47d52f2799f91c423f5b9d87fbd51b1265d58753f"
          .hexToBech32("xpub");

  final acc = await CardanoPubAccountWorkerFactory.instance.fromBech32XPub(xpub);
  final start = DateTime.now();
  for (var i = 0; i < addressCount; i++) {
    await acc.rolePublicKey(Bip32KeyRole.payment, i);
  }
  final end = DateTime.now();
  print(end.difference(start).inMilliseconds);
}

Future<void> deriveFromMnemonic() async {
  const mnemonic =
      "chief fiber betray curve tissue output feature jungle adapt smile brown crane accuse gospel plate unlock pull arrow hard february tape soccer patrol fetch";
  final wallet = await WalletFactory.fromMnemonic(NetworkId.mainnet, mnemonic.split(" "));
  final start = DateTime.now();
  for (var i = 0; i < addressCount; i++) {
    await wallet.getPaymentAddressKit(addressIndex: i);
  }
  final end = DateTime.now();
  print(end.difference(start).inMilliseconds);
}
void main() async {
  await deriveFromMnemonic();
  await deriveFromXPub();
}

// ignore: unreachable_from_main, avoid_void_async
void main2() async {
  // THIS EXAMPLE CONTAINS SIGNATURE DATA FROM LEDGER
  final messageHex =
      "I am logging in to jpg.store. My verification code is: 490398171".utf8ToHex();
  const sig =
      "9f7a907dcf5bd765d929354d157dd83d7e9f42ea1dd57cb3c3fb925d8cd24665050a1c25b0bd59ca19ed1ab45fd41dfef3c9bb42122fef01c20d624ad800d00a";
  const addr = "e557890352095f1cf6fd2b7d1a28e3c3cb029f48cf34ff890a28d176";
  final vkeyHex = "012f5dc3115b8a07981e6e50f5a671e2c6fbb26c3ffde1cd1dcaf40a7fe8f160".hexDecode();

  final vk = VerifyKey(vkeyHex);

  final headers = CoseHeaders(
    protectedHeader: CoseProtectedHeaderMap(
      bytes: CoseHeaderMap(
        algorithmId: const CborSmallInt(ALG_EdDSA),
        keyId: null,
        otherHeaders: CborMap.of({
          CborString(ADDRESS_KEY): CborBytes(addr.hexDecode()),
        }),
      ).serializeAsBytes(),
    ),
    unprotectedHeader: CoseHeaderMap(hashed: false, otherHeaders: CborMap.of({})),
  );

  final sigStructure = CoseSigStructure.fromSign1(
    bodyProtected: headers.protectedHeader,
    payload: messageHex.hexDecode(),
  );
  final dataToSign = sigStructure.serializeAsBytes();

  final valid = vk.verify(
    signature: Signature(sig.hexDecode()),
    message: dataToSign,
  );

  print(valid);
}
