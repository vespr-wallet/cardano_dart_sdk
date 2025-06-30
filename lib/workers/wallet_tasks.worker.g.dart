// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_tasks.dart';

// **************************************************************************
// Generator: WorkerGenerator 6.2.0
// **************************************************************************

/// WorkerService class for WalletTasks
class _$WalletTasksWorkerService extends WalletTasks implements WorkerService {
  _$WalletTasksWorkerService() : super();

  @override
  late final Map<int, CommandHandler> operations =
      Map.unmodifiable(<int, CommandHandler>{
    _$buildHdWalletFromMnemonicId: ($) => buildHdWalletFromMnemonic(
            _$X.$impl.$dsr0($.args[0]), _$X.$impl.$dsr1($.args[1]))
        .then(_$X.$impl.$sr2),
    _$buildHdWalletFromSeedId: ($) => buildHdWalletFromSeed(
            _$X.$impl.$dsr3($.args[0]), _$X.$impl.$dsr1($.args[1]))
        .then(_$X.$impl.$sr2),
    _$buildWalletFromHdWalletId: ($) => buildWalletFromHdWallet(
            _$X.$impl.$dsr4($.args[0]), _$X.$impl.$dsr5($.args[1]))
        .then(_$X.$impl.$sr6),
    _$ckdPubBip32Ed25519KeyDerivationId: ($) => ckdPubBip32Ed25519KeyDerivation(
            _$X.$impl.$dsr7($.args[0]), _$X.$impl.$dsr1($.args[1]))
        .then(_$X.$impl.$sr8),
    _$ckdPubBip32Ed25519KeyDerivationsId: ($) =>
        ckdPubBip32Ed25519KeyDerivations(_$X.$impl.$dsr7($.args[0]),
                _$X.$impl.$dsr1($.args[1]), _$X.$impl.$dsr1($.args[2]))
            .then(_$X.$impl.$sr9),
    _$deriveAddressKitId: ($) => deriveAddressKit(
            _$X.$impl.$dsr4($.args[0]),
            _$X.$impl.$dsr5($.args[1]),
            _$X.$impl.$dsr1($.args[2]),
            _$X.$impl.$dsr10($.args[3]))
        .then(_$X.$impl.$sr11),
    _$hexCredentialsDerivationId: ($) => hexCredentialsDerivation(
            _$X.$impl.$dsr7($.args[0]),
            _$X.$impl.$dsr1($.args[1]),
            _$X.$impl.$dsr1($.args[2]))
        .then(_$X.$impl.$sr12),
    _$prepareTxsForSigningImplId: ($) => prepareTxsForSigningImpl(
            _$X.$impl.$dsr13($.args[0]),
            _$X.$impl.$dsr13($.args[1]),
            _$X.$impl.$dsr13($.args[2]),
            _$X.$impl.$dsr13($.args[3]),
            _$X.$impl.$dsr5($.args[4]),
            _$X.$impl.$dsr14($.args[5]),
            _$X.$impl.$dsr15($.args[6]))
        .then(_$X.$impl.$sr16),
    _$signDataId: ($) => signData(
            _$X.$impl.$dsr17($.args[0]),
            _$X.$impl.$dsr13($.args[1]),
            _$X.$impl.$dsr13($.args[2]),
            _$X.$impl.$dsr1($.args[3]))
        .then(_$X.$impl.$sr18),
    _$signTransactionsBundleId: ($) => signTransactionsBundle(
            _$X.$impl.$dsr17($.args[0]),
            _$X.$impl.$dsr19($.args[1]),
            _$X.$impl.$dsr1($.args[2]))
        .then(_$X.$impl.$sr20),
    _$toCardanoBaseAddressId: ($) => toCardanoBaseAddress(
            _$X.$impl.$dsr7($.args[0]),
            _$X.$impl.$dsr7($.args[1]),
            _$X.$impl.$dsr5($.args[2]),
            paymentType: _$X.$impl.$dsr21($.args[3]),
            stakeType: _$X.$impl.$dsr21($.args[4]))
        .then(_$X.$impl.$sr22),
    _$toCardanoRewardAddressId: ($) => toCardanoRewardAddress(
            _$X.$impl.$dsr7($.args[0]), _$X.$impl.$dsr5($.args[1]),
            paymentType: _$X.$impl.$dsr21($.args[2]))
        .then(_$X.$impl.$sr22),
  });

  static const int _$buildHdWalletFromMnemonicId = 1;
  static const int _$buildHdWalletFromSeedId = 2;
  static const int _$buildWalletFromHdWalletId = 3;
  static const int _$ckdPubBip32Ed25519KeyDerivationId = 4;
  static const int _$ckdPubBip32Ed25519KeyDerivationsId = 5;
  static const int _$deriveAddressKitId = 6;
  static const int _$hexCredentialsDerivationId = 7;
  static const int _$prepareTxsForSigningImplId = 8;
  static const int _$signDataId = 9;
  static const int _$signTransactionsBundleId = 10;
  static const int _$toCardanoBaseAddressId = 11;
  static const int _$toCardanoRewardAddressId = 12;
}

/// Service initializer for WalletTasks
WorkerService $WalletTasksInitializer(WorkerRequest $$) =>
    _$WalletTasksWorkerService();

/// Worker for WalletTasks
base class WalletTasksWorker extends Worker implements WalletTasks {
  WalletTasksWorker(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($WalletTasksActivator(Squadron.platformType));

  WalletTasksWorker.vm(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($WalletTasksActivator(SquadronPlatformType.vm));

  WalletTasksWorker.js(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($WalletTasksActivator(SquadronPlatformType.js),
            threadHook: threadHook, exceptionManager: exceptionManager);

  WalletTasksWorker.wasm(
      {PlatformThreadHook? threadHook, ExceptionManager? exceptionManager})
      : super($WalletTasksActivator(SquadronPlatformType.wasm));

  @override
  Future<HdWallet> buildHdWalletFromMnemonic(
          List<String> mnemonic, int accountIndex) =>
      send(_$WalletTasksWorkerService._$buildHdWalletFromMnemonicId,
              args: [_$X.$impl.$sr12(mnemonic), accountIndex])
          .then(_$X.$impl.$dsr4);

  @override
  Future<HdWallet> buildHdWalletFromSeed(Uint8List seed, int accountIndex) =>
      send(_$WalletTasksWorkerService._$buildHdWalletFromSeedId,
          args: [_$X.$impl.$sr23(seed), accountIndex]).then(_$X.$impl.$dsr4);

  @override
  Future<CardanoWallet> buildWalletFromHdWallet(
          HdWallet hdWallet, NetworkId networkId) =>
      send(_$WalletTasksWorkerService._$buildWalletFromHdWalletId,
              args: [_$X.$impl.$sr2(hdWallet), _$X.$impl.$sr24(networkId)])
          .then(_$X.$impl.$dsr17);

  @override
  Future<Bip32PublicKey> ckdPubBip32Ed25519KeyDerivation(
          Bip32PublicKey pubKey, int index) =>
      send(_$WalletTasksWorkerService._$ckdPubBip32Ed25519KeyDerivationId,
          args: [_$X.$impl.$sr8(pubKey), index]).then(_$X.$impl.$dsr7);

  @override
  Future<List<Bip32PublicKey>> ckdPubBip32Ed25519KeyDerivations(
          Bip32PublicKey pubKey,
          int startIndexInclusive,
          int endIndexExclusive) =>
      send(_$WalletTasksWorkerService._$ckdPubBip32Ed25519KeyDerivationsId,
          args: [
            _$X.$impl.$sr8(pubKey),
            startIndexInclusive,
            endIndexExclusive
          ]).then(_$X.$impl.$dsr25);

  @override
  Future<CardanoAddressKit> deriveAddressKit(
          HdWallet wallet, NetworkId networkId, int index, Bip32KeyRole role) =>
      send(_$WalletTasksWorkerService._$deriveAddressKitId, args: [
        _$X.$impl.$sr2(wallet),
        _$X.$impl.$sr24(networkId),
        index,
        _$X.$impl.$sr26(role)
      ]).then(_$X.$impl.$dsr27);

  @override
  Future<List<String>> hexCredentialsDerivation(Bip32PublicKey pubKey,
          int startIndexInclusive, int endIndexExclusive) =>
      send(_$WalletTasksWorkerService._$hexCredentialsDerivationId, args: [
        _$X.$impl.$sr8(pubKey),
        startIndexInclusive,
        endIndexExclusive
      ]).then(_$X.$impl.$dsr0);

  @override
  Future<TxSigningBundle> prepareTxsForSigningImpl(
          String walletBech32Address,
          String drepCredential,
          String constitutionalCommitteeColdCredential,
          String constitutionalCommitteeHotCredential,
          NetworkId networkId,
          List<CardanoTransaction> txs,
          List<Utxo> utxos) =>
      send(_$WalletTasksWorkerService._$prepareTxsForSigningImplId, args: [
        walletBech32Address,
        drepCredential,
        constitutionalCommitteeColdCredential,
        constitutionalCommitteeHotCredential,
        _$X.$impl.$sr24(networkId),
        _$X.$impl.$sr28(txs),
        _$X.$impl.$sr29(utxos)
      ]).then(_$X.$impl.$dsr19);

  @override
  Future<DataSignature> signData(CardanoWallet wallet, String payloadHex,
          String requestedSignerRaw, int deriveMaxAddressCount) =>
      send(_$WalletTasksWorkerService._$signDataId, args: [
        _$X.$impl.$sr6(wallet),
        payloadHex,
        requestedSignerRaw,
        deriveMaxAddressCount
      ]).then(_$X.$impl.$dsr30);

  @override
  Future<TxSignedBundle> signTransactionsBundle(CardanoWallet wallet,
          TxSigningBundle bundle, int deriveMaxAddressCount) =>
      send(_$WalletTasksWorkerService._$signTransactionsBundleId, args: [
        _$X.$impl.$sr6(wallet),
        _$X.$impl.$sr16(bundle),
        deriveMaxAddressCount
      ]).then(_$X.$impl.$dsr31);

  @override
  Future<CardanoAddress> toCardanoBaseAddress(
          Bip32PublicKey spend, Bip32PublicKey stake, NetworkId networkId,
          {CredentialType paymentType = CredentialType.key,
          CredentialType stakeType = CredentialType.key}) =>
      send(_$WalletTasksWorkerService._$toCardanoBaseAddressId, args: [
        _$X.$impl.$sr8(spend),
        _$X.$impl.$sr8(stake),
        _$X.$impl.$sr24(networkId),
        _$X.$impl.$sr32(paymentType),
        _$X.$impl.$sr32(stakeType)
      ]).then(_$X.$impl.$dsr33);

  @override
  Future<CardanoAddress> toCardanoRewardAddress(
          Bip32PublicKey spend, NetworkId networkId,
          {CredentialType paymentType = CredentialType.key}) =>
      send(_$WalletTasksWorkerService._$toCardanoRewardAddressId, args: [
        _$X.$impl.$sr8(spend),
        _$X.$impl.$sr24(networkId),
        _$X.$impl.$sr32(paymentType)
      ]).then(_$X.$impl.$dsr33);
}

/// Worker pool for WalletTasks
base class WalletTasksWorkerPool extends WorkerPool<WalletTasksWorker>
    implements WalletTasks {
  WalletTasksWorkerPool(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => WalletTasksWorker(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  WalletTasksWorkerPool.vm(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => WalletTasksWorker.vm(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  WalletTasksWorkerPool.js(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => WalletTasksWorker.js(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  WalletTasksWorkerPool.wasm(
      {ConcurrencySettings? concurrencySettings,
      PlatformThreadHook? threadHook,
      ExceptionManager? exceptionManager})
      : super(
          (ExceptionManager exceptionManager) => WalletTasksWorker.wasm(
              threadHook: threadHook, exceptionManager: exceptionManager),
          concurrencySettings: concurrencySettings,
        );

  @override
  Future<HdWallet> buildHdWalletFromMnemonic(
          List<String> mnemonic, int accountIndex) =>
      execute((w) => w.buildHdWalletFromMnemonic(mnemonic, accountIndex));

  @override
  Future<HdWallet> buildHdWalletFromSeed(Uint8List seed, int accountIndex) =>
      execute((w) => w.buildHdWalletFromSeed(seed, accountIndex));

  @override
  Future<CardanoWallet> buildWalletFromHdWallet(
          HdWallet hdWallet, NetworkId networkId) =>
      execute((w) => w.buildWalletFromHdWallet(hdWallet, networkId));

  @override
  Future<Bip32PublicKey> ckdPubBip32Ed25519KeyDerivation(
          Bip32PublicKey pubKey, int index) =>
      execute((w) => w.ckdPubBip32Ed25519KeyDerivation(pubKey, index));

  @override
  Future<List<Bip32PublicKey>> ckdPubBip32Ed25519KeyDerivations(
          Bip32PublicKey pubKey,
          int startIndexInclusive,
          int endIndexExclusive) =>
      execute((w) => w.ckdPubBip32Ed25519KeyDerivations(
          pubKey, startIndexInclusive, endIndexExclusive));

  @override
  Future<CardanoAddressKit> deriveAddressKit(
          HdWallet wallet, NetworkId networkId, int index, Bip32KeyRole role) =>
      execute((w) => w.deriveAddressKit(wallet, networkId, index, role));

  @override
  Future<List<String>> hexCredentialsDerivation(Bip32PublicKey pubKey,
          int startIndexInclusive, int endIndexExclusive) =>
      execute((w) => w.hexCredentialsDerivation(
          pubKey, startIndexInclusive, endIndexExclusive));

  @override
  Future<TxSigningBundle> prepareTxsForSigningImpl(
          String walletBech32Address,
          String drepCredential,
          String constitutionalCommitteeColdCredential,
          String constitutionalCommitteeHotCredential,
          NetworkId networkId,
          List<CardanoTransaction> txs,
          List<Utxo> utxos) =>
      execute((w) => w.prepareTxsForSigningImpl(
          walletBech32Address,
          drepCredential,
          constitutionalCommitteeColdCredential,
          constitutionalCommitteeHotCredential,
          networkId,
          txs,
          utxos));

  @override
  Future<DataSignature> signData(CardanoWallet wallet, String payloadHex,
          String requestedSignerRaw, int deriveMaxAddressCount) =>
      execute((w) => w.signData(
          wallet, payloadHex, requestedSignerRaw, deriveMaxAddressCount));

  @override
  Future<TxSignedBundle> signTransactionsBundle(CardanoWallet wallet,
          TxSigningBundle bundle, int deriveMaxAddressCount) =>
      execute((w) =>
          w.signTransactionsBundle(wallet, bundle, deriveMaxAddressCount));

  @override
  Future<CardanoAddress> toCardanoBaseAddress(
          Bip32PublicKey spend, Bip32PublicKey stake, NetworkId networkId,
          {CredentialType paymentType = CredentialType.key,
          CredentialType stakeType = CredentialType.key}) =>
      execute((w) => w.toCardanoBaseAddress(spend, stake, networkId,
          paymentType: paymentType, stakeType: stakeType));

  @override
  Future<CardanoAddress> toCardanoRewardAddress(
          Bip32PublicKey spend, NetworkId networkId,
          {CredentialType paymentType = CredentialType.key}) =>
      execute((w) =>
          w.toCardanoRewardAddress(spend, networkId, paymentType: paymentType));
}

final class _$X {
  _$X._();

  static _$X? _impl;

  static _$X get $impl {
    if (_impl == null) {
      Squadron.onConverterChanged(() => _impl = _$X._());
      _impl = _$X._();
    }
    return _impl!;
  }

  late final $dsr0 = (($) => (const StringListMarshaler()).unmarshal($));
  late final $dsr1 = Squadron.converter.value<int>();
  late final $sr2 = (($) => (const HdWalletMarshaler()).marshal($));
  late final $dsr3 =
      (($) => (const TypedDataMarshaler<Uint8List>()).unmarshal($));
  late final $dsr4 = (($) => (const HdWalletMarshaler()).unmarshal($));
  late final $dsr5 = (($) => (const NetworkIdMarshaler()).unmarshal($));
  late final $sr6 = (($) => (const WalletMarshaler()).marshal($));
  late final $dsr7 = (($) => (const Bip32PublicKeyKeyMarshaler()).unmarshal($));
  late final $sr8 = (($) => (const Bip32PublicKeyKeyMarshaler()).marshal($));
  late final $sr9 = (($) => (const Bip32PublicKeysKeyMarshaler()).marshal($));
  late final $dsr10 = (($) => (const Bip32KeyRoleMarshaler()).unmarshal($));
  late final $sr11 = (($) => (const CardanoAddressKitMarshaler()).marshal($));
  late final $sr12 = (($) => (const StringListMarshaler()).marshal($));
  late final $dsr13 = Squadron.converter.value<String>();
  late final $dsr14 =
      (($) => (const CardanoTransactionListMarshaler()).unmarshal($));
  late final $dsr15 = (($) => (const UtxoListMarshaler()).unmarshal($));
  late final $sr16 = (($) => (const TxSigningBundleMarshaler()).marshal($));
  late final $dsr17 = (($) => (const WalletMarshaler()).unmarshal($));
  late final $sr18 = (($) => (const DataSignatureMarshaler()).marshal($));
  late final $dsr19 = (($) => (const TxSigningBundleMarshaler()).unmarshal($));
  late final $sr20 = (($) => (const TxSignedBundleMarshaler()).marshal($));
  late final $dsr21 = (($) => (const CredentialTypeMarshaler()).unmarshal($));
  late final $sr22 = (($) => (const CardanoAddressMarshaler()).marshal($));
  late final $sr23 =
      (($) => (const TypedDataMarshaler<Uint8List>()).marshal($));
  late final $sr24 = (($) => (const NetworkIdMarshaler()).marshal($));
  late final $dsr25 =
      (($) => (const Bip32PublicKeysKeyMarshaler()).unmarshal($));
  late final $sr26 = (($) => (const Bip32KeyRoleMarshaler()).marshal($));
  late final $dsr27 =
      (($) => (const CardanoAddressKitMarshaler()).unmarshal($));
  late final $sr28 =
      (($) => (const CardanoTransactionListMarshaler()).marshal($));
  late final $sr29 = (($) => (const UtxoListMarshaler()).marshal($));
  late final $dsr30 = (($) => (const DataSignatureMarshaler()).unmarshal($));
  late final $dsr31 = (($) => (const TxSignedBundleMarshaler()).unmarshal($));
  late final $sr32 = (($) => (const CredentialTypeMarshaler()).marshal($));
  late final $dsr33 = (($) => (const CardanoAddressMarshaler()).unmarshal($));
}
