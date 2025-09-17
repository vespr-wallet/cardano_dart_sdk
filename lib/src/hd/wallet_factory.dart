import "package:bip32_ed25519/cardano.dart";
import "package:bip39_plus/bip39_plus.dart" as bip39;
import "package:cardano_dart_types/cardano_dart_types.dart";

import "../../workers/wallet_tasks.dart";
import "address/hd_wallet.dart";

class WalletFactory {
  WalletFactory._();

  static List<String> generateNewMnemonic({MnemonicsWordsCount wordsCount = MnemonicsWordsCount.w15}) =>
      bip39.generateMnemonic(strength: wordsCount.strength).split(" ");

  static Future<CardanoWallet> fromMnemonic(
    NetworkId networkId,
    List<String> mnemonic, {
    int accountIndex = defaultAccountIndex,
  }) async => fromHdWallet(
    networkId,
    await HdWalletFactory.fromMnemonic(mnemonic, accountIndex: accountIndex),
  );

  static Future<CardanoWallet> fromSeed(NetworkId networkId, ByteList seed) async => fromHdWallet(
    networkId,
    await HdWalletFactory.fromSeed(seed),
  );

  static Future<CardanoWallet> fromHdWallet(NetworkId networkId, HdWallet hdWallet) async =>
      cardanoWorker.buildWalletFromHdWallet(hdWallet, networkId);
}

class HdWalletFactory {
  HdWalletFactory._();

  static Future<HdWallet> fromMnemonic(List<String> mnemonic, {int accountIndex = defaultAccountIndex}) =>
      cardanoWorker.buildHdWalletFromMnemonic(mnemonic, accountIndex);

  static Future<HdWallet> fromSeed(ByteList seed, {int accountIndex = defaultAccountIndex}) =>
      cardanoWorker.buildHdWalletFromSeed(seed.asTypedList, accountIndex);
}
