// ignore_for_file: dead_code, avoid_print test

import "package:bip32_ed25519/api.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:cardano_flutter_sdk/src/utils/sugar.dart";

void main() async {
  // Squadron.debugMode = true;
  // Squadron.logLevel = SquadronLogLevel.all;
  // Squadron.setLogger(ConsoleSquadronLogger());

  const addrBech =
      "addr1qy7zq8euhjzsvyvw62gpngccxy7u09px7qywvpnwlyx9wdjzsc087dxtm2kss6620yc7lfrdj5sjd5s5nlx4hcwm2jusrwj7dj";

  final addrHex = addrBech.bech32ToHex();

  print(addrHex);

  return;

  const mnemonic =
      "chief fiber betray curve tissue output feature jungle adapt smile brown crane accuse gospel plate unlock pull arrow hard february tape soccer patrol fetch";
  final mn = mnemonic.split(" ");
  print('Wallet: ${mn.join(' ')}');

  final wallet = await WalletFactory.fromMnemonic(NetworkId.mainnet, mn);

  final addr = await wallet.getPaymentAddressKit(addressIndex: 0);
  print("addr: ${addr.address.bech32Encoded}");
  // print(addr.address.bech32Encode().hexDecode());
  print(blake2bHash224(addr.verifyKey).hexEncode());
  print(addr.address.hexEncoded.take(56));

  print("Address is: ${wallet.firstAddress.bech32Encoded}");
  print(wallet.stakeAddress.bech32Encoded);

  print(wallet.firstAddress.bech32Encoded);
  const Bip32Ed25519KeyDerivation derivator = Bip32Ed25519KeyDerivation.instance;

  // final firstAddress = wallet.hdWallet.toBaseAddress(spend: firstAddressKeyPair.verifyKey, networkId: networkId);

  // final stakeKeyPair = hdWallet.stakeAddressKeys;
  // final stakeAddress = hdWallet.toRewardAddress(spend: stakeKeyPair.verifyKey, networkId: networkId);

  final firstAddressKeyPair =
      (wallet as CardanoWalletImpl).hdWallet.deriveAddressKeys(role: Bip32KeyRole.payment, index: 0);

  // final keyFromPub1 = derivator.ckdPub(wallet.hdWallet.accountPublicKey.verifyKey, 0);
  // final keyFromPub2 = derivator.ckdPub(wallet.hdWallet.accountPublicKey.publicKey, 0);
  final keyFromNeutered = derivator.ckdPub(wallet.hdWallet.accountPublicKey.neutered, 0);
  // print(keyFromPub1.toUint8List().hexEncode());
  // print(keyFromPub2.toUint8List().hexEncode());
  print(keyFromNeutered.toUint8List().hexEncode());

  final keyFromPubL1 = derivator.ckdPub(wallet.hdWallet.accountPublicKey, 0);
  final keyFromPubL2 = derivator.ckdPub(keyFromPubL1, 0);
  for (var i = 0; i <= 4; i++) {
    // final keyFromPubL2 = derivator.ckdPub(keyFromPubL1, i);
    // print(keyFromPubL2.);
  }

  print(firstAddressKeyPair.verifyKey.toUint8List().hexEncode());
  print(keyFromPubL2.toUint8List().hexEncode());
  // print(keyFromPriv.publicKey.toUint8List().hexEncode());

  final baseAddrFromPub = wallet.hdWallet.toBaseAddress(spendVerifyKey: keyFromPubL2, networkId: NetworkId.testnet);
  print(wallet.firstAddress.bech32Encoded);
  print(baseAddrFromPub.bech32Encoded);
}
