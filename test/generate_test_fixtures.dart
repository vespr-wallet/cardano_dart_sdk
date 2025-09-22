// ignore_for_file: avoid_print
// This file generates test fixtures for wallet_tasks_sign_test.dart

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";

void main() async {
  // Using the xpub from example/verify_signature_example.dart
  const xpubHex =
      "ba6dc7a16ebcffd7a029a8f534fe826f229deaa09e28cf548e56dcf803a7189acf49ed29a83927bd23ff965c6904733f015cacf231835c32f760e0274dff0052";
  final xpubBech32 = xpubHex.hexToBech32("xpub");

  print("Using xpub (hex): $xpubHex");
  print("Using xpub (bech32): $xpubBech32");
  print("");

  // Create pub account from xpub
  final pubAccount = await CardanoPubAccountWorkerFactory.instance.fromHexXPub(xpubHex);

  print("=== TESTNET ADDRESSES ===");
  print("");

  // Generate payment addresses
  print("Payment addresses:");
  for (int i = 0; i < 3; i++) {
    final addr = await pubAccount.paymentAddress(i, NetworkId.testnet);
    final addrBech32 = await pubAccount.paymentBech32Address(i, NetworkId.testnet);
    final addrPublicKey = await pubAccount.paymentPublicKey(i);
    print("  Index $i:");
    print("    Bech32: $addrBech32");
    print("    Hex:    ${addr.hexEncoded}");
    print("    Public Key:    ${addrPublicKey.rawKey.hexEncode()}");
  }
  print("");

  // Generate change addresses
  print("Change addresses:");
  for (int i = 0; i < 3; i++) {
    final addr = await pubAccount.changeAddress(i, NetworkId.testnet);
    final addrBech32 = await pubAccount.changeBech32Address(i, NetworkId.testnet);
    final addrPublicKey = await pubAccount.changePublicKey(i);
    print("  Index $i:");
    print("    Bech32: $addrBech32");
    print("    Hex:    ${addr.hexEncoded}");
    print("    Public Key:    ${addrPublicKey.rawKey.hexEncode()}");
  }
  print("");

  // Generate stake address
  print("Stake address - testnet:");
  final stakeAddrTestnet = await pubAccount.stakeAddress(NetworkId.testnet);
  final stakeAddrMainnet = await pubAccount.stakeAddress(NetworkId.mainnet);
  final stakeDerivation = pubAccount.stakeDerivation.value;
  print("  Bech32 Mainnet: $stakeAddrMainnet");
  print("  Hex Mainnet:    ${stakeAddrMainnet.bech32ToHex()}");
  print("  Bech32 Testnet: $stakeAddrTestnet");
  print("  Hex Testnet:    ${stakeAddrTestnet.bech32ToHex()}");
  print("  Credentials: ${stakeDerivation.credentialsHex}");
  print("  Key Hex: ${stakeDerivation.keyHex}");
  print("");

  // Generate DRep info
  print("DRep information:");
  final drepDerivation = pubAccount.dRepDerivation.value;
  print("  DRep ID OLD (creds bech): ${drepDerivation.dRepIdLegacyBech32}");
  print("  DRep ID OLD (creds hex): ${drepDerivation.dRepIdLegacyHex}");
  print("  DRep ID NEW (bech): ${drepDerivation.dRepIdNewBech32}");
  print("  DRep ID NEW (hex): ${drepDerivation.dRepIdNewHex}");
  print("  DRep Key Hex: ${drepDerivation.dRepKeyHex}");
  print("");

  // Generate CC keys
  print("Constitutional Committee:");
  final ccCold = pubAccount.constitutionalCommitteeColdDerivation.value;
  final ccHot = pubAccount.constitutionalCommitteeHotDerivation.value;
  print("  Cold Key Hex: ${ccCold.hexCCKey}");
  print("  Hot Key Hex:  ${ccHot.hexCCKey}");
  print("");

  print("=== MAINNET ADDRESSES ===");
  print("");

  // Generate mainnet addresses
  print("Mainnet payment address (index 0):");
  final mainnetPaymentAddr = await pubAccount.paymentBech32Address(0, NetworkId.mainnet);
  print("  Bech32: $mainnetPaymentAddr");
  print("  Hex:    ${(await pubAccount.paymentAddress(0, NetworkId.mainnet)).hexEncoded}");
  print("");

  print("Mainnet stake address:");
  final mainnetStakeAddr = await pubAccount.stakeAddress(NetworkId.mainnet);
  print("  Bech32: $mainnetStakeAddr");
  print("  Hex:    ${mainnetStakeAddr.bech32ToHex()}");
  print("");

  // Get public keys for validation
  print("=== PUBLIC KEYS ===");
  print("");
  for (int i = 0; i < 2; i++) {
    final paymentPubKey = await pubAccount.paymentPublicKey(i);
    final changePubKey = await pubAccount.changePublicKey(i);
    print("Index $i:");
    print("  Payment public key: ${paymentPubKey.rawKey.hexEncode()}");
    print("  Change public key:  ${changePubKey.rawKey.hexEncode()}");
  }

  print("");
  print("Stake public key: ${stakeDerivation.bytes.hexEncode()}");
  print("DRep public key:  ${drepDerivation.bytes.hexEncode()}");
}
