// ignore_for_file: avoid_print

import "package:bip32_ed25519/api.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";

void main() async {
  // THIS EXAMPLE CONTAINS SIGNATURE DATA FROM LEDGER
  const messageHex =
      "535441522037363736303136343920746f2061646472317138707668656868687875766561637676716e3936676d79717171633568717167797a6c6464777633677467643861306a6a346d34327236673876366d3234757074376c6c6c6e736c6d7a32376e643530796335726c7a636e6e3873636b647338352033316136626162353061383462383433396164636662373836626232303230663638303765366538666461363239623432343131306663376262316336623862";
  const sig =
      "16acce5836bbf54d892dd8d694c53c50c569ecf013d18b666933fee86adb0530ab86ef06085053059bd7889d815ecec795260b092af82748a31bf43c8935820f";
  final vkeyHex = "b3d5f4158f0c391ee2a28a2e285f218f3e895ff6ff59cb9369c64b03b5bab5eb".hexDecode();
  const addr = "5a53103829a7382c2ab76111fb69f13e69d616824c62058e44f1a8b3";

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
