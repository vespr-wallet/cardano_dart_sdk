import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:test/test.dart";

void main() async {
  const mnemonic =
      "chief fiber betray curve tissue output feature jungle adapt smile brown crane accuse gospel plate unlock pull arrow hard february tape soccer patrol fetch";

  final wallet = await WalletFactory.fromMnemonic(NetworkId.testnet, mnemonic.split(" "));

  test("address kit marshall", () async {
    final kit = await wallet.getPaymentAddressKit(addressIndex: 1);
    final unmarshalled = CardanoAddressKit.unmarshal(kit.marshal());
    expect(unmarshalled.account, equals(kit.account));
    expect(unmarshalled.role, equals(kit.role));
    expect(unmarshalled.index, equals(kit.index));
    expect(unmarshalled.address, equals(kit.address));
    expect(unmarshalled.signingKey, equals(kit.signingKey));
    expect(unmarshalled.verifyKey, equals(kit.verifyKey));
  });
}
