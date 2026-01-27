// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'wallet_tasks.dart';

// **************************************************************************
// Generator: WorkerGenerator 9.0.0+2 (Squadron 7.4.0)
// **************************************************************************

// dart format width=80
/// Command ids used in operations map
const int _$buildHdWalletFromMnemonicId = 1;
const int _$buildHdWalletFromSeedId = 2;
const int _$buildWalletFromHdWalletId = 3;
const int _$ckdPubBip32Ed25519KeyDerivationId = 4;
const int _$ckdPubBip32Ed25519KeyDerivationsId = 5;
const int _$deriveAddressKitId = 6;
const int _$findCardanoSignerId = 7;
const int _$hexCredentialsDerivationId = 8;
const int _$prepareTxsForSigningImplId = 9;
const int _$signDataLegacyId = 10;
const int _$signDataV2Id = 11;
const int _$signTransactionsBundleId = 12;
const int _$toCardanoBaseAddressId = 13;
const int _$toCardanoRewardAddressId = 14;

/// WorkerService operations for WalletTasks
extension on WalletTasks {
  OperationsMap _$getOperations() => OperationsMap({
    _$buildHdWalletFromMnemonicId: ($req) async {
      final HdWallet $res;
      try {
        final $dsr = _$Deser(contextAware: true);
        $res = await buildHdWalletFromMnemonic(
          $dsr.$0($req.args[0]),
          $dsr.$1($req.args[1]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$0($res);
      } finally {}
    },
    _$buildHdWalletFromSeedId: ($req) async {
      final HdWallet $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await buildHdWalletFromSeed(
          $dsr.$2($req.args[0]),
          $dsr.$1($req.args[1]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$0($res);
      } finally {}
    },
    _$buildWalletFromHdWalletId: ($req) async {
      final CardanoWallet $res;
      try {
        final $dsr = _$Deser(contextAware: true);
        $res = await buildWalletFromHdWallet(
          $dsr.$3($req.args[0]),
          $dsr.$4($req.args[1]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$1($res);
      } finally {}
    },
    _$ckdPubBip32Ed25519KeyDerivationId: ($req) async {
      final Bip32PublicKey $res;
      try {
        final $dsr = _$Deser(contextAware: true);
        $res = await ckdPubBip32Ed25519KeyDerivation(
          $dsr.$5($req.args[0]),
          $dsr.$1($req.args[1]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$2($res);
      } finally {}
    },
    _$ckdPubBip32Ed25519KeyDerivationsId: ($req) async {
      final List<Bip32PublicKey> $res;
      try {
        final $dsr = _$Deser(contextAware: true);
        $res = await ckdPubBip32Ed25519KeyDerivations(
          $dsr.$5($req.args[0]),
          $dsr.$1($req.args[1]),
          $dsr.$1($req.args[2]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$3($res);
      } finally {}
    },
    _$deriveAddressKitId: ($req) async {
      final CardanoAddressKit $res;
      try {
        final $dsr = _$Deser(contextAware: true);
        $res = await deriveAddressKit(
          $dsr.$3($req.args[0]),
          $dsr.$4($req.args[1]),
          $dsr.$1($req.args[2]),
          $dsr.$6($req.args[3]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$4($res);
      } finally {}
    },
    _$findCardanoSignerId: ($req) async {
      final CardanoSigner $res;
      try {
        final $dsr = _$Deser(contextAware: false);
        $res = await findCardanoSigner(
          $dsr.$7($req.args[0]),
          $dsr.$7($req.args[1]),
          $dsr.$1($req.args[2]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$5($res);
      } finally {}
    },
    _$hexCredentialsDerivationId: ($req) async {
      final List<String> $res;
      try {
        final $dsr = _$Deser(contextAware: true);
        $res = await hexCredentialsDerivation(
          $dsr.$5($req.args[0]),
          $dsr.$1($req.args[1]),
          $dsr.$1($req.args[2]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$6($res);
      } finally {}
    },
    _$prepareTxsForSigningImplId: ($req) async {
      final TxSigningBundle $res;
      try {
        final $dsr = _$Deser(contextAware: true);
        $res = await prepareTxsForSigningImpl(
          $dsr.$7($req.args[0]),
          $dsr.$7($req.args[1]),
          $dsr.$7($req.args[2]),
          $dsr.$7($req.args[3]),
          $dsr.$4($req.args[4]),
          $dsr.$8($req.args[5]),
          $dsr.$9($req.args[6]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$7($res);
      } finally {}
    },
    _$signDataLegacyId: ($req) async {
      final DataSignature $res;
      try {
        final $dsr = _$Deser(contextAware: true);
        $res = await signDataLegacy(
          $dsr.$10($req.args[0]),
          $dsr.$7($req.args[1]),
          $dsr.$7($req.args[2]),
          $dsr.$1($req.args[3]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$8($res);
      } finally {}
    },
    _$signDataV2Id: ($req) async {
      final DataSignature $res;
      try {
        final $dsr = _$Deser(contextAware: true);
        $res = await signDataV2(
          $dsr.$10($req.args[0]),
          $dsr.$7($req.args[1]),
          $dsr.$7($req.args[2]),
          $dsr.$1($req.args[3]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$8($res);
      } finally {}
    },
    _$signTransactionsBundleId: ($req) async {
      final TxSignedBundle $res;
      try {
        final $dsr = _$Deser(contextAware: true);
        $res = await signTransactionsBundle(
          $dsr.$10($req.args[0]),
          $dsr.$11($req.args[1]),
          $dsr.$1($req.args[2]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$9($res);
      } finally {}
    },
    _$toCardanoBaseAddressId: ($req) async {
      final CardanoAddress $res;
      try {
        final $dsr = _$Deser(contextAware: true);
        $res = await toCardanoBaseAddress(
          $dsr.$5($req.args[0]),
          $dsr.$5($req.args[1]),
          $dsr.$4($req.args[2]),
          paymentType: $dsr.$12($req.args[3]),
          stakeType: $dsr.$12($req.args[4]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$10($res);
      } finally {}
    },
    _$toCardanoRewardAddressId: ($req) async {
      final CardanoAddress $res;
      try {
        final $dsr = _$Deser(contextAware: true);
        $res = await toCardanoRewardAddress(
          $dsr.$5($req.args[0]),
          $dsr.$4($req.args[1]),
          paymentType: $dsr.$12($req.args[2]),
        );
      } finally {}
      try {
        final $sr = _$Ser(contextAware: true);
        return $sr.$10($res);
      } finally {}
    },
  });
}

/// Invoker for WalletTasks, implements the public interface to invoke the
/// remote service.
mixin _$WalletTasks$Invoker on Invoker implements WalletTasks {
  @override
  Future<HdWallet> buildHdWalletFromMnemonic(
    List<String> mnemonic,
    int accountIndex,
  ) async {
    final dynamic $res;
    try {
      final $sr = _$Ser(contextAware: true);
      $res = await send(
        _$buildHdWalletFromMnemonicId,
        args: [$sr.$6(mnemonic), accountIndex],
      );
    } finally {}
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$3($res);
    } finally {}
  }

  @override
  Future<HdWallet> buildHdWalletFromSeed(
    Uint8List seed,
    int accountIndex,
  ) async {
    final dynamic $res = await send(
      _$buildHdWalletFromSeedId,
      args: [seed, accountIndex],
    );
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$3($res);
    } finally {}
  }

  @override
  Future<CardanoWallet> buildWalletFromHdWallet(
    HdWallet hdWallet,
    NetworkId networkId,
  ) async {
    final dynamic $res;
    try {
      final $sr = _$Ser(contextAware: true);
      $res = await send(
        _$buildWalletFromHdWalletId,
        args: [$sr.$0(hdWallet), $sr.$11(networkId)],
      );
    } finally {}
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$10($res);
    } finally {}
  }

  @override
  Future<Bip32PublicKey> ckdPubBip32Ed25519KeyDerivation(
    Bip32PublicKey pubKey,
    int index,
  ) async {
    final dynamic $res;
    try {
      final $sr = _$Ser(contextAware: true);
      $res = await send(
        _$ckdPubBip32Ed25519KeyDerivationId,
        args: [$sr.$2(pubKey), index],
      );
    } finally {}
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$5($res);
    } finally {}
  }

  @override
  Future<List<Bip32PublicKey>> ckdPubBip32Ed25519KeyDerivations(
    Bip32PublicKey pubKey,
    int startIndexInclusive,
    int endIndexExclusive,
  ) async {
    final dynamic $res;
    try {
      final $sr = _$Ser(contextAware: true);
      $res = await send(
        _$ckdPubBip32Ed25519KeyDerivationsId,
        args: [$sr.$2(pubKey), startIndexInclusive, endIndexExclusive],
      );
    } finally {}
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$13($res);
    } finally {}
  }

  @override
  Future<CardanoAddressKit> deriveAddressKit(
    HdWallet wallet,
    NetworkId networkId,
    int index,
    Bip32KeyRole role,
  ) async {
    final dynamic $res;
    try {
      final $sr = _$Ser(contextAware: true);
      $res = await send(
        _$deriveAddressKitId,
        args: [$sr.$0(wallet), $sr.$11(networkId), index, $sr.$12(role)],
      );
    } finally {}
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$14($res);
    } finally {}
  }

  @override
  Future<CardanoSigner> findCardanoSigner(
    String xPubHex,
    String requestedSignerRaw,
    int deriveMaxAddressCount,
  ) async {
    final dynamic $res = await send(
      _$findCardanoSignerId,
      args: [xPubHex, requestedSignerRaw, deriveMaxAddressCount],
    );
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$15($res);
    } finally {}
  }

  @override
  Future<List<String>> hexCredentialsDerivation(
    Bip32PublicKey pubKey,
    int startIndexInclusive,
    int endIndexExclusive,
  ) async {
    final dynamic $res;
    try {
      final $sr = _$Ser(contextAware: true);
      $res = await send(
        _$hexCredentialsDerivationId,
        args: [$sr.$2(pubKey), startIndexInclusive, endIndexExclusive],
      );
    } finally {}
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$0($res);
    } finally {}
  }

  @override
  Future<TxSigningBundle> prepareTxsForSigningImpl(
    String walletBech32Address,
    String drepCredential,
    String constitutionalCommitteeColdCredential,
    String constitutionalCommitteeHotCredential,
    NetworkId networkId,
    List<CardanoTransaction> txs,
    List<Utxo> utxos,
  ) async {
    final dynamic $res;
    try {
      final $sr = _$Ser(contextAware: true);
      $res = await send(
        _$prepareTxsForSigningImplId,
        args: [
          walletBech32Address,
          drepCredential,
          constitutionalCommitteeColdCredential,
          constitutionalCommitteeHotCredential,
          $sr.$11(networkId),
          $sr.$13(txs),
          $sr.$14(utxos),
        ],
      );
    } finally {}
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$11($res);
    } finally {}
  }

  @override
  Future<DataSignature> signDataLegacy(
    CardanoWallet wallet,
    String payloadHex,
    String requestedSignerRaw,
    int deriveMaxAddressCount,
  ) async {
    final dynamic $res;
    try {
      final $sr = _$Ser(contextAware: true);
      $res = await send(
        _$signDataLegacyId,
        args: [
          $sr.$1(wallet),
          payloadHex,
          requestedSignerRaw,
          deriveMaxAddressCount,
        ],
      );
    } finally {}
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$16($res);
    } finally {}
  }

  @override
  Future<DataSignature> signDataV2(
    CardanoWalletImpl wallet,
    String payloadHex,
    String requestedSignerRaw,
    int deriveMaxAddressCount,
  ) async {
    final dynamic $res;
    try {
      final $sr = _$Ser(contextAware: true);
      $res = await send(
        _$signDataV2Id,
        args: [
          $sr.$1(wallet),
          payloadHex,
          requestedSignerRaw,
          deriveMaxAddressCount,
        ],
      );
    } finally {}
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$16($res);
    } finally {}
  }

  @override
  Future<TxSignedBundle> signTransactionsBundle(
    CardanoWallet wallet,
    TxSigningBundle bundle,
    int deriveMaxAddressCount,
  ) async {
    final dynamic $res;
    try {
      final $sr = _$Ser(contextAware: true);
      $res = await send(
        _$signTransactionsBundleId,
        args: [$sr.$1(wallet), $sr.$7(bundle), deriveMaxAddressCount],
      );
    } finally {}
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$17($res);
    } finally {}
  }

  @override
  Future<CardanoAddress> toCardanoBaseAddress(
    Bip32PublicKey spend,
    Bip32PublicKey stake,
    NetworkId networkId, {
    CredentialType paymentType = CredentialType.key,
    CredentialType stakeType = CredentialType.key,
  }) async {
    final dynamic $res;
    try {
      final $sr = _$Ser(contextAware: true);
      $res = await send(
        _$toCardanoBaseAddressId,
        args: [
          $sr.$2(spend),
          $sr.$2(stake),
          $sr.$11(networkId),
          $sr.$15(paymentType),
          $sr.$15(stakeType),
        ],
      );
    } finally {}
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$18($res);
    } finally {}
  }

  @override
  Future<CardanoAddress> toCardanoRewardAddress(
    Bip32PublicKey spend,
    NetworkId networkId, {
    CredentialType paymentType = CredentialType.key,
  }) async {
    final dynamic $res;
    try {
      final $sr = _$Ser(contextAware: true);
      $res = await send(
        _$toCardanoRewardAddressId,
        args: [$sr.$2(spend), $sr.$11(networkId), $sr.$15(paymentType)],
      );
    } finally {}
    try {
      final $dsr = _$Deser(contextAware: true);
      return $dsr.$18($res);
    } finally {}
  }
}

/// Facade for WalletTasks, implements other details of the service unrelated to
/// invoking the remote service.
mixin _$WalletTasks$Facade implements WalletTasks {}

/// WorkerClient for WalletTasks
final class $WalletTasks$Client extends WorkerClient
    with _$WalletTasks$Invoker, _$WalletTasks$Facade
    implements WalletTasks {
  $WalletTasks$Client(PlatformChannel channelInfo)
    : super(Channel.deserialize(channelInfo)!);
}

/// Local worker extension for WalletTasks
extension $WalletTasksLocalWorkerExt on WalletTasks {
  // Get a fresh local worker instance.
  LocalWorker<WalletTasks> getLocalWorker([
    ExceptionManager? exceptionManager,
  ]) => LocalWorker.create(this, _$getOperations(), exceptionManager);
}

/// WorkerService class for WalletTasks
class _$WalletTasks$WorkerService extends WalletTasks implements WorkerService {
  _$WalletTasks$WorkerService() : super();

  @override
  OperationsMap get operations => _$getOperations();
}

/// Service initializer for WalletTasks
WorkerService $WalletTasksInitializer(WorkerRequest $req) =>
    _$WalletTasks$WorkerService();

/// Worker for WalletTasks
base class WalletTasksWorker extends Worker
    with _$WalletTasks$Invoker, _$WalletTasks$Facade
    implements WalletTasks {
  WalletTasksWorker({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $WalletTasksActivator(Squadron.platformType),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  WalletTasksWorker.vm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $WalletTasksActivator(SquadronPlatformType.vm),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  WalletTasksWorker.js({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $WalletTasksActivator(SquadronPlatformType.js),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  WalletTasksWorker.wasm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
  }) : super(
         $WalletTasksActivator(SquadronPlatformType.wasm),
         threadHook: threadHook,
         exceptionManager: exceptionManager,
       );

  @override
  List? getStartArgs() => null;
}

/// Worker pool for WalletTasks
base class WalletTasksWorkerPool extends WorkerPool<WalletTasksWorker>
    with _$WalletTasks$Facade
    implements WalletTasks {
  WalletTasksWorkerPool({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => WalletTasksWorker(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  WalletTasksWorkerPool.vm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => WalletTasksWorker.vm(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  WalletTasksWorkerPool.js({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => WalletTasksWorker.js(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  WalletTasksWorkerPool.wasm({
    PlatformThreadHook? threadHook,
    ExceptionManager? exceptionManager,
    ConcurrencySettings? concurrencySettings,
  }) : super(
         (ExceptionManager exceptionManager) => WalletTasksWorker.wasm(
           threadHook: threadHook,
           exceptionManager: exceptionManager,
         ),
         concurrencySettings: concurrencySettings,
         exceptionManager: exceptionManager,
       );

  @override
  Future<HdWallet> buildHdWalletFromMnemonic(
    List<String> mnemonic,
    int accountIndex,
  ) => execute((w) => w.buildHdWalletFromMnemonic(mnemonic, accountIndex));

  @override
  Future<HdWallet> buildHdWalletFromSeed(Uint8List seed, int accountIndex) =>
      execute((w) => w.buildHdWalletFromSeed(seed, accountIndex));

  @override
  Future<CardanoWallet> buildWalletFromHdWallet(
    HdWallet hdWallet,
    NetworkId networkId,
  ) => execute((w) => w.buildWalletFromHdWallet(hdWallet, networkId));

  @override
  Future<Bip32PublicKey> ckdPubBip32Ed25519KeyDerivation(
    Bip32PublicKey pubKey,
    int index,
  ) => execute((w) => w.ckdPubBip32Ed25519KeyDerivation(pubKey, index));

  @override
  Future<List<Bip32PublicKey>> ckdPubBip32Ed25519KeyDerivations(
    Bip32PublicKey pubKey,
    int startIndexInclusive,
    int endIndexExclusive,
  ) => execute(
    (w) => w.ckdPubBip32Ed25519KeyDerivations(
      pubKey,
      startIndexInclusive,
      endIndexExclusive,
    ),
  );

  @override
  Future<CardanoAddressKit> deriveAddressKit(
    HdWallet wallet,
    NetworkId networkId,
    int index,
    Bip32KeyRole role,
  ) => execute((w) => w.deriveAddressKit(wallet, networkId, index, role));

  @override
  Future<CardanoSigner> findCardanoSigner(
    String xPubHex,
    String requestedSignerRaw,
    int deriveMaxAddressCount,
  ) => execute(
    (w) =>
        w.findCardanoSigner(xPubHex, requestedSignerRaw, deriveMaxAddressCount),
  );

  @override
  Future<List<String>> hexCredentialsDerivation(
    Bip32PublicKey pubKey,
    int startIndexInclusive,
    int endIndexExclusive,
  ) => execute(
    (w) => w.hexCredentialsDerivation(
      pubKey,
      startIndexInclusive,
      endIndexExclusive,
    ),
  );

  @override
  Future<TxSigningBundle> prepareTxsForSigningImpl(
    String walletBech32Address,
    String drepCredential,
    String constitutionalCommitteeColdCredential,
    String constitutionalCommitteeHotCredential,
    NetworkId networkId,
    List<CardanoTransaction> txs,
    List<Utxo> utxos,
  ) => execute(
    (w) => w.prepareTxsForSigningImpl(
      walletBech32Address,
      drepCredential,
      constitutionalCommitteeColdCredential,
      constitutionalCommitteeHotCredential,
      networkId,
      txs,
      utxos,
    ),
  );

  @override
  Future<DataSignature> signDataLegacy(
    CardanoWallet wallet,
    String payloadHex,
    String requestedSignerRaw,
    int deriveMaxAddressCount,
  ) => execute(
    (w) => w.signDataLegacy(
      wallet,
      payloadHex,
      requestedSignerRaw,
      deriveMaxAddressCount,
    ),
  );

  @override
  Future<DataSignature> signDataV2(
    CardanoWalletImpl wallet,
    String payloadHex,
    String requestedSignerRaw,
    int deriveMaxAddressCount,
  ) => execute(
    (w) => w.signDataV2(
      wallet,
      payloadHex,
      requestedSignerRaw,
      deriveMaxAddressCount,
    ),
  );

  @override
  Future<TxSignedBundle> signTransactionsBundle(
    CardanoWallet wallet,
    TxSigningBundle bundle,
    int deriveMaxAddressCount,
  ) => execute(
    (w) => w.signTransactionsBundle(wallet, bundle, deriveMaxAddressCount),
  );

  @override
  Future<CardanoAddress> toCardanoBaseAddress(
    Bip32PublicKey spend,
    Bip32PublicKey stake,
    NetworkId networkId, {
    CredentialType paymentType = CredentialType.key,
    CredentialType stakeType = CredentialType.key,
  }) => execute(
    (w) => w.toCardanoBaseAddress(
      spend,
      stake,
      networkId,
      paymentType: paymentType,
      stakeType: stakeType,
    ),
  );

  @override
  Future<CardanoAddress> toCardanoRewardAddress(
    Bip32PublicKey spend,
    NetworkId networkId, {
    CredentialType paymentType = CredentialType.key,
  }) => execute(
    (w) => w.toCardanoRewardAddress(spend, networkId, paymentType: paymentType),
  );
}

final class _$Deser extends MarshalingContext {
  _$Deser({super.contextAware});
  late final $0 = (($) => stringListMarshaler.unmarshal($, this));
  late final $1 = value<int>();
  late final $2 = value<Uint8List>();
  late final $3 = (($) => hdWalletMarshaler.unmarshal($, this));
  late final $4 = (($) => networkIdMarshaler.unmarshal($, this));
  late final $5 = (($) => bip32PublicKeyKeyMarshaler.unmarshal($, this));
  late final $6 = (($) => bip32KeyRoleMarshaler.unmarshal($, this));
  late final $7 = value<String>();
  late final $8 = (($) => cardanoTransactionListMarshaler.unmarshal($, this));
  late final $9 = (($) => utxoListMarshaler.unmarshal($, this));
  late final $10 = (($) => walletMarshaler.unmarshal($, this));
  late final $11 = (($) => txSigningBundleMarshaler.unmarshal($, this));
  late final $12 = (($) => credentialTypeMarshaler.unmarshal($, this));
  late final $13 = (($) => bip32PublicKeysKeyMarshaler.unmarshal($, this));
  late final $14 = (($) => cardanoAddressKitMarshaler.unmarshal($, this));
  late final $15 = (($) => cardanoSignerMarshaler.unmarshal($, this));
  late final $16 = (($) => dataSignatureMarshaler.unmarshal($, this));
  late final $17 = (($) => txSignedBundleMarshaler.unmarshal($, this));
  late final $18 = (($) => cardanoAddressMarshaler.unmarshal($, this));
}

final class _$Ser extends MarshalingContext {
  _$Ser({super.contextAware});
  late final $0 = (($) => hdWalletMarshaler.marshal($, this));
  late final $1 = (($) => walletMarshaler.marshal($, this));
  late final $2 = (($) => bip32PublicKeyKeyMarshaler.marshal($, this));
  late final $3 = (($) => bip32PublicKeysKeyMarshaler.marshal($, this));
  late final $4 = (($) => cardanoAddressKitMarshaler.marshal($, this));
  late final $5 = (($) => cardanoSignerMarshaler.marshal($, this));
  late final $6 = (($) => stringListMarshaler.marshal($, this));
  late final $7 = (($) => txSigningBundleMarshaler.marshal($, this));
  late final $8 = (($) => dataSignatureMarshaler.marshal($, this));
  late final $9 = (($) => txSignedBundleMarshaler.marshal($, this));
  late final $10 = (($) => cardanoAddressMarshaler.marshal($, this));
  late final $11 = (($) => networkIdMarshaler.marshal($, this));
  late final $12 = (($) => bip32KeyRoleMarshaler.marshal($, this));
  late final $13 = (($) => cardanoTransactionListMarshaler.marshal($, this));
  late final $14 = (($) => utxoListMarshaler.marshal($, this));
  late final $15 = (($) => credentialTypeMarshaler.marshal($, this));
}
