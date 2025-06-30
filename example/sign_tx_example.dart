// ignore_for_file: avoid_print example

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";

void main() async {
  const NetworkId network = NetworkId.testnet;
  const String mnemonic =
      "chief fiber betray curve tissue output feature jungle adapt smile brown crane accuse gospel plate unlock pull arrow hard february tape soccer patrol fetch";

  final CardanoWallet wallet = await WalletFactory.fromMnemonic(network, mnemonic.split(" "));

  const String hexTx =
      "84a50081825820d4ff0c6b532d6dcdffe463f700e339a103fc131a2fd5c6e8df6d04c7d2b92d7200018182583900e53a24b2fbeeef3bc3adc55622092cc8c172fad61c231d1358e5f023272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f0729341b0000000253eab5f3021a0002a98d031a0026c6f9048282008200581c272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f07293483028200581c272d0b87fb7b9561d4d3dee46b8d422a8a8ec555c514e2b15f072934581c576dd569a2fced24213236fcbb99b7892b0aac973429ab2afc85e383a0f5f6";

  final parsedTx = CardanoTransaction.deserializeFromHex(hexTx);

  final witnessSet = await wallet.signTransaction(
    tx: parsedTx,
    witnessBech32Addresses: {
      "addr_test1qq54j5r58k7z4u9hlxqv54kq675s0q98rn3439pnuv60lhf8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q6traa6"
    },
  );

  final signedTx = parsedTx.copyWithAdditionalSignatures(witnessSet);

  print(signedTx.serializeHexString());
}
