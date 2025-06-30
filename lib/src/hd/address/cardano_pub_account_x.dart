import "dart:async";

import "package:bip32_ed25519/api.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";
import "../../../workers/wallet_tasks.dart";

extension CardanoPubAccountX on CardanoPubAccount {
  Future<List<String>> deriveCredentialsHex({
    required int startIndex,
    required int endIndex,
    required Bip32KeyRole role,
  }) =>
      cardanoWorker.hexCredentialsDerivation(
        _rolePublicKey(role),
        startIndex,
        endIndex,
      );

  Future<Bip32PublicKey> paymentPublicKey(int index) => _deriveAsync(paymentRoleKey, index);
  Future<List<Bip32PublicKey>> paymentPublicKeys(int startIndex, int endIndex) =>
      _multiDeriveAsync(paymentRoleKey, startIndex, endIndex);

  Future<Bip32PublicKey> changePublicKey(int index) => _deriveAsync(changeRoleKey, index);
  Future<List<Bip32PublicKey>> changePublicKeys(int startIndex, int endIndex) =>
      _multiDeriveAsync(changeRoleKey, startIndex, endIndex);

  Future<Bip32PublicKey> stakePublicKey({int index = 0}) => _deriveAsync(stakeRoleKey, index);

  Future<Bip32PublicKey> rolePublicKey(Bip32KeyRole role, int index) => _deriveAsync(_rolePublicKey(role), index);

  Future<CardanoAddress> paymentAddress(int index, NetworkId networkId) async {
    final spendPubKey = await _deriveAsync(paymentRoleKey, index);
    return cardanoWorker.toCardanoBaseAddress(spendPubKey, stakeKey, networkId);
  }

  Future<CardanoAddress> changeAddress(int index, NetworkId networkId) async {
    final spendPubKey = await _deriveAsync(changeRoleKey, index);
    return cardanoWorker.toCardanoBaseAddress(spendPubKey, stakeKey, networkId);
  }

  Future<CardanoAddress> stakeCardanoAddress(NetworkId networkId) =>
      cardanoWorker.toCardanoRewardAddress(stakeKey, networkId);

  Future<String> paymentBech32Address(int index, NetworkId networkId) =>
      paymentAddress(index, networkId).then((addr) => addr.bech32Encoded);
  Future<String> changeBech32Address(int index, NetworkId networkId) =>
      changeAddress(index, networkId).then((addr) => addr.bech32Encoded);
  Future<String> stakeAddress(NetworkId networkId) => //
      stakeCardanoAddress(networkId).then((addr) => addr.bech32Encoded);

  Future<String> paymentCredentialsHex(int index) => // Network id is irrelevant for creds
      paymentAddress(index, NetworkId.mainnet).then((addr) => addr.credentials);
  Future<String> changeCredentialsHex(int index) => // Network id is irrelevant for creds
      changeAddress(index, NetworkId.mainnet).then((addr) => addr.credentials);
  Future<String> stakeCredentialsHex() => //
      stakeCardanoAddress(NetworkId.mainnet).then((addr) => addr.credentials);

  Bip32PublicKey _rolePublicKey(Bip32KeyRole role) => switch (role) {
        Bip32KeyRole.payment => paymentRoleKey,
        Bip32KeyRole.change => changeRoleKey,
        Bip32KeyRole.staking => stakeRoleKey,
        Bip32KeyRole.drepCredential => drepIdRoleKey,
        Bip32KeyRole.constitutionalCommitteeCold => constitutionalCommitteeColdRoleKey,
        Bip32KeyRole.constitutionalCommitteeHot => constitutionalCommitteeHotRoleKey,
      };
}

class CardanoPubAccountWorkerFactory extends CardanoPubAccountFactory {
  static final CardanoPubAccountWorkerFactory instance = CardanoPubAccountWorkerFactory._();

  CardanoPubAccountWorkerFactory._() : super(cardanoWorker.ckdPubBip32Ed25519KeyDerivation);
}

Future<Bip32PublicKey> _deriveAsync(Bip32PublicKey parent, int index) =>
    cardanoWorker.ckdPubBip32Ed25519KeyDerivation(parent, index);

Future<List<Bip32PublicKey>> _multiDeriveAsync(Bip32PublicKey parent, int startIndex, int endIndex) =>
    cardanoWorker.ckdPubBip32Ed25519KeyDerivations(parent, startIndex, endIndex);
