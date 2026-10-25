@TestOn("browser")
library;

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/workers/marshaler.web.dart";
import "package:test/test.dart";

// Web only: on the VM, transactions reach the worker as they are (dart test -P js / -P wasm)
void main() {
  test("transactions keep the hash of a body that does not re-serialize to its bytes", () {
    // fee 10 with a non-minimal head (18 0a)
    final tx = CardanoTransaction.deserializeFromHex(
      "84a3008001800218"
      "0aa0f5f6",
    );
    expect(tx.body.computeBlake2bHash256().hexEncode(), isNot(tx.body.blake2bHash256Hex()));

    final unmarshaled = cardanoTransactionListMarshaler.unmarshal(cardanoTransactionListMarshaler.marshal([tx]));
    expect(unmarshaled.single.body.blake2bHash256Hex(), tx.body.blake2bHash256Hex());
  });
}
