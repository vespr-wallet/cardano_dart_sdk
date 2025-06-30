// ignore_for_file: dead_code, avoid_print

import "package:bip32_ed25519/api.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:cardano_flutter_sdk/src/utils/derivation_utils.dart";

void main() async {
  // Squadron.debugMode = true;
  // Squadron.logLevel = SquadronLogLevel.all;
  // Squadron.setLogger(ConsoleSquadronLogger());

  const xpub =
      "xpub1m8k3509pmpjajnl630f56wtkrac9nw30p7edfvenxkzwl78ar62zvejs7qmze5wmqrwakgwdcmau422c7umhve2ahluelyxxkvk7ulcquemdm";

  final acc = await CardanoPubAccountWorkerFactory.instance.fromBech32XPub(xpub);
  print(await acc.stakeAddress(NetworkId.mainnet));
  // print(acc.stakeDerivation.value.)
  for (var i = 0; i < 5; i++) {
    print("index: $i");
    print((await acc.paymentAddress(i, NetworkId.mainnet)).bech32Encoded);
    print((await acc.changeAddress(i, NetworkId.mainnet)).bech32Encoded);
  }
  print(await acc.paymentPublicKey(1));
  print(await acc.paymentPublicKey(1));
  print(await acc.stakeAddress(NetworkId.mainnet));
  return;

  final xPubBytes = xpub.bech32Decode();

  // Bip32PublicKey;

  final key = Bip32VerifyKey.fromKeyBytes(
    xPubBytes.take(32).toUint8List(), // 32 bytes raw public key
    xPubBytes.skip(32).toUint8List(), // 32 bytes chain code
  );

  // derive payment pub key
  final paymentRole = DerivationUtils.derivePublicKey(pubKey: key, index: 0);
  final paymentAddress0PubKey = DerivationUtils.derivePublicKey(pubKey: paymentRole, index: 0);
  final paymentAddress1PubKey = DerivationUtils.derivePublicKey(pubKey: paymentRole, index: 1);

  // derive change pub key
  final changeRole = DerivationUtils.derivePublicKey(pubKey: key, index: 1);
  final changeAddress0PubKey = DerivationUtils.derivePublicKey(pubKey: changeRole, index: 0);
  final changeAddress1PubKey = DerivationUtils.derivePublicKey(pubKey: changeRole, index: 1);

  // derive stake
  final stakeRole = DerivationUtils.derivePublicKey(pubKey: key, index: 2);
  final stakeAddressPubKey = DerivationUtils.derivePublicKey(pubKey: stakeRole, index: 0);

  final stakeAddr = CardanoAddress.toRewardAddress(
    spend: stakeAddressPubKey,
    networkId: NetworkId.mainnet,
  );
  final change0Addr = CardanoAddress.toBaseAddress(
    spend: changeAddress0PubKey,
    stake: stakeAddressPubKey,
    networkId: NetworkId.mainnet,
  );
  final change1Addr = CardanoAddress.toBaseAddress(
    spend: changeAddress1PubKey,
    stake: stakeAddressPubKey,
    networkId: NetworkId.mainnet,
  );

  final spend0Addr = CardanoAddress.toBaseAddress(
    spend: paymentAddress0PubKey,
    stake: stakeAddressPubKey,
    networkId: NetworkId.mainnet,
  );

  final spend1Addr = CardanoAddress.toBaseAddress(
    spend: paymentAddress1PubKey,
    stake: stakeAddressPubKey,
    networkId: NetworkId.mainnet,
  );

  // print bech32 address and credentials
  print("staking address:");
  print(stakeAddr.bech32Encoded);
  print(stakeAddr.credentials);
  print("");

  print("spending address - index 0:");
  print(spend0Addr.bech32Encoded);
  print(spend0Addr.credentials);
  print("");

  print("spending address - index 1:");
  print(spend1Addr.bech32Encoded);
  print(spend1Addr.credentials);
  print("");

  print("change address - index 0:");
  print(change0Addr.bech32Encoded);
  print(change0Addr.credentials);
  print("");
  print("change address - index 1:");
  print(change1Addr.bech32Encoded);
  print(change1Addr.credentials);
  print("");
}
