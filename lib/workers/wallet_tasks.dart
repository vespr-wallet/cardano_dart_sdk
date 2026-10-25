import "dart:async";

import "package:bip32_ed25519/bip32_ed25519.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:collection/collection.dart";
import "package:squadron/squadron.dart";

import "../cardano_flutter_sdk.dart";
import "../src/utils/iterable_extensions.dart";
import "marshaler.vm.dart" //
    if (dart.library.js) "marshaler.web.dart"
    if (dart.library.js_interop) "marshaler.web.dart"
    if (dart.library.html) "marshaler.web.dart";
import "wallet_tasks.activator.g.dart";
import "wallet_tasks_sign.dart";

part "wallet_tasks.worker.g.dart";

final WalletTasks cardanoWorker = WalletTasksWorkerPool(
  concurrencySettings: const ConcurrencySettings(
    maxWorkers: 10,
    minWorkers: 0,
    // Temporary fix for the issue with the worker pool where nested worker tasks get scheduled on the same worker
    // --- using maxParallel to 1 would cause a deadlock for nested worker tasks
    // --- [in squadrion 6.0.3]
    maxParallel: 4,
  ),
)..start();

// @UseLogger(ConsoleSquadronLogger)
@SquadronService(
  baseUrl: "/assets/packages/cardano_flutter_sdk/workers",
)
class WalletTasks {
  @SquadronMethod()
  @cardanoAddressMarshaler
  Future<CardanoAddress> toCardanoBaseAddress(
    @bip32PublicKeyKeyMarshaler Bip32PublicKey spend,
    @bip32PublicKeyKeyMarshaler Bip32PublicKey stake,
    @networkIdMarshaler NetworkId networkId, {
    @credentialTypeMarshaler CredentialType paymentType = CredentialType.key,
    @credentialTypeMarshaler CredentialType stakeType = CredentialType.key,
  }) async => CardanoAddress.toBaseAddress(
    spend: spend,
    stake: stake,
    networkId: networkId,
    paymentType: paymentType,
    stakeType: stakeType,
  );

  @SquadronMethod()
  @cardanoAddressMarshaler
  Future<CardanoAddress> toCardanoRewardAddress(
    @bip32PublicKeyKeyMarshaler Bip32PublicKey spend,
    @networkIdMarshaler NetworkId networkId, {
    @credentialTypeMarshaler CredentialType paymentType = CredentialType.key,
  }) async => CardanoAddress.toRewardAddress(
    spend: spend,
    networkId: networkId,
    paymentType: paymentType,
  );

  @SquadronMethod()
  @bip32PublicKeyKeyMarshaler
  Future<Bip32PublicKey> ckdPubBip32Ed25519KeyDerivation(
    // verify key is the public key
    @bip32PublicKeyKeyMarshaler Bip32PublicKey pubKey,
    int index,
  ) async => Bip32Ed25519KeyDerivation.instance.ckdPub(pubKey, index);

  @SquadronMethod()
  @bip32PublicKeysKeyMarshaler
  Future<List<Bip32PublicKey>> ckdPubBip32Ed25519KeyDerivations(
    // verify key is the public key
    @bip32PublicKeyKeyMarshaler Bip32PublicKey pubKey,
    int startIndexInclusive,
    int endIndexExclusive,
  ) async => List.generate(
    endIndexExclusive - startIndexInclusive,
    (index) => Bip32Ed25519KeyDerivation.instance.ckdPub(pubKey, startIndexInclusive + index),
  );

  @SquadronMethod()
  @stringListMarshaler
  Future<List<String>> hexCredentialsDerivation(
    // verify key is the public key
    @bip32PublicKeyKeyMarshaler Bip32PublicKey pubKey,
    int startIndexInclusive,
    int endIndexExclusive,
  ) async => List.generate(
    endIndexExclusive - startIndexInclusive,
    (index) => blake2bHash224(
      Bip32Ed25519KeyDerivation.instance.ckdPub(pubKey, startIndexInclusive + index).rawKey,
    ).hexEncode(),
  );

  @SquadronMethod()
  @hdWalletMarshaler
  Future<HdWallet> buildHdWalletFromMnemonic(
    @stringListMarshaler List<String> mnemonic,
    int accountIndex,
  ) async => HdWallet.fromMnemonic(mnemonic.join(" "), accountIndex: accountIndex);

  @SquadronMethod()
  @hdWalletMarshaler
  Future<HdWallet> buildHdWalletFromSeed(Uint8List seed, int accountIndex) async =>
      HdWallet.fromSeed(seed, accountIndex: accountIndex);

  @SquadronMethod()
  @cardanoAddressKitMarshaler
  Future<CardanoAddressKit> deriveAddressKit(
    @hdWalletMarshaler HdWallet wallet,
    @networkIdMarshaler NetworkId networkId,
    int index,
    @bip32KeyRoleMarshaler Bip32KeyRole role,
  ) async => wallet.deriveBaseAddressKit(index: index, role: role, networkId: networkId);

  @SquadronMethod()
  @walletMarshaler
  Future<CardanoWallet> buildWalletFromHdWallet(
    @hdWalletMarshaler HdWallet hdWallet,
    @networkIdMarshaler NetworkId networkId,
  ) async {
    final firstAddressKeyPair = hdWallet.deriveAddressKeys(role: Bip32KeyRole.payment, index: 0);
    final firstAddress = hdWallet.toBaseAddress(spendVerifyKey: firstAddressKeyPair.verifyKey, networkId: networkId);

    final stakeAddress = hdWallet.toRewardAddress(networkId: networkId);

    return CardanoWalletImpl(
      firstAddress: firstAddress,
      stakeAddress: stakeAddress,
      hdWallet: hdWallet,
      accountIndex: hdWallet.accountIndex,
    );
  }

  @SquadronMethod()
  @txSigningBundleMarshaler
  Future<TxSigningBundle> prepareTxsForSigningImpl(
    String walletBech32Address,
    String drepCredential,
    String constitutionalCommitteeColdCredential,
    String constitutionalCommitteeHotCredential,
    @networkIdMarshaler NetworkId networkId,
    @cardanoTransactionListMarshaler List<CardanoTransaction> txs,
    @utxoListMarshaler List<Utxo> utxos,
  ) async {
    final bech32Address = walletBech32Address;

    final txsPreparedForSigning = List<TxPreparedForSigning>.empty(growable: true);

    var walletUtxosBeforeTx = utxos;

    for (final CardanoTransaction tx in txs) {
      // Refused before summarising: the summary of a transaction meant for another network is meaningless
      _requireBoundToNetwork(tx: tx, walletNetwork: networkId);
      final txHash = tx.body.blake2bHash256Hex();

      // Key on the hash hex, not on TransactionHash.toString(): that would include CBOR metadata (tags, length type)
      // and a parsed input would not match the same UTxO as held by the wallet.
      final usedUtxosTxAndId = tx.body.inputs.data.map((e) => "${e.transactionHash.hexValue}#${e.index}").toSet();
      final collateralUtxosTxAndId = tx.body.collateral?.data
          .map((e) => "${e.transactionHash.hexValue}#${e.index}")
          .toSet();

      final txUtxos = {...usedUtxosTxAndId, ...?collateralUtxosTxAndId};
      final Set<String> signatureAddresses = walletUtxosBeforeTx
          // find all wallet utxos used in this tx
          .where((e) => txUtxos.contains("${e.identifier.transactionHash.hexValue}#${e.identifier.index}"))
          // get the wallet addresses needed to sign the used wallet utxos
          .map((e) => e.content.address.base58OrBech32Value)
          .toSet();

      final List<Utxo> notUsedUserUtxos = walletUtxosBeforeTx
          .where((e) => !usedUtxosTxAndId.contains("${e.identifier.transactionHash.hexValue}#${e.identifier.index}"))
          .toList();
      final List<Utxo> generatedUserUtxos = tx.body.outputs
          .mapIndexed<Utxo?>(
            (utxoIndex, e) => e.address.base58OrBech32Value != bech32Address
                ? null
                : Utxo(
                    identifier: CardanoTransactionInput(
                      transactionHash: TransactionHash.fromHex(txHash),
                      index: utxoIndex,
                    ),
                    content: e,
                  ),
          )
          .nonNulls
          .toList();

      txsPreparedForSigning.add(
        TxPreparedForSigning(
          tx: tx,
          // This summary is shown before signing. The isValid flag is not part of the signed body and can be switched
          // after signing, so a transaction marked as failing phase-2 validation is refused rather than summarised.
          // Stated explicitly even though it is the default; see TxDiManagement.
          txDiff: tx.diff(
            receiveAddressBech32: bech32Address,
            walletUtxos: walletUtxosBeforeTx,
            drepCredential: drepCredential,
            constitutionalCommitteeColdCredential: constitutionalCommitteeColdCredential,
            constitutionalCommitteeHotCredential: constitutionalCommitteeHotCredential,
            txDiManagement: TxDiManagement.safeAlwaysReject,
          ),
          utxosBeforeTx: walletUtxosBeforeTx,
          signingAddressesRequired: signatureAddresses,
        ),
      );

      // for next iteration, update the utxos
      walletUtxosBeforeTx = [...notUsedUserUtxos, ...generatedUserUtxos];
    }

    final txsTotalDiff = txsPreparedForSigning.reduceSafe(
      initialValue: Value.v0(lovelace: BigInt.zero.toCborInt()),
      combine: (aggregator, e) => aggregator + e.txDiff.diff,
    );

    return TxSigningBundle(
      receiveAddressBech32: bech32Address,
      networkId: networkId,
      txsData: txsPreparedForSigning,
      totalDiff: txsTotalDiff,
      stakeDelegationPoolId: txsPreparedForSigning.map((e) => e.txDiff.stakeDelegationPoolId).nonNulls.lastOrNull,
      dRepDeregistration: txsPreparedForSigning.any((e) => e.txDiff.dRepDeregistration),
      stakeDeregistration: txsPreparedForSigning.any((e) => e.txDiff.stakeDeregistration),
      authorizeConstitutionalCommitteeHot: txsPreparedForSigning
          .map((e) => e.txDiff.authorizeConstitutionalCommitteeHot)
          .nonNulls
          .lastOrNull,
      resignConstitutionalCommitteeCold: txsPreparedForSigning
          .map((e) => e.txDiff.resignConstitutionalCommitteeCold)
          .nonNulls
          .lastOrNull,
      dRepDelegation: txsPreparedForSigning.map((e) => e.txDiff.dRepDelegation).nonNulls.lastOrNull,
      dRepRegistration: txsPreparedForSigning.map((e) => e.txDiff.dRepRegistration).nonNulls.lastOrNull,
      dRepUpdate: txsPreparedForSigning.map((e) => e.txDiff.dRepUpdate).nonNulls.lastOrNull,
      votes: txsPreparedForSigning.map((e) => e.txDiff.votes).nonNulls.flattened.toList(),
      proposals: txsPreparedForSigning.map((e) => e.txDiff.proposals).nonNulls.flattened.toList(),
    );
  }

  @SquadronMethod()
  @txSignedBundleMarshaler
  Future<TxSignedBundle> signTransactionsBundle(
    @walletMarshaler CardanoWallet wallet,
    @txSigningBundleMarshaler TxSigningBundle bundle,
    int deriveMaxAddressCount,
  ) async {
    final txs = bundle.txsData;

    final HdWallet hdWallet = (wallet as CardanoWalletImpl).hdWallet;
    final networkId = wallet.networkId;

    // Checked here too: signTransaction and hand-built bundles do not go through prepareTxsForSigningImpl
    for (final e in txs) {
      _requireBoundToNetwork(tx: e.tx, walletNetwork: networkId);
    }

    final List<Set<Bip32KeyPair>> signAddressesAll = List.generate(txs.length, (index) => {});
    final List<Set<String>> modifiableSpendCredentialsAll = List.generate(
      txs.length,
      (index) => Set.of(
        txs[index] //
            .signingAddressesRequired
            .map((e) => CardanoAddress.fromBech32OrBase58(e).credentials),
      ),
    );

    final modifiablePubKeyNativeScriptCredentialsAll = List.generate(
      txs.length,
      (index) => _credsFromNativeScripts(txs[index].tx.witnessSet.nativeScripts).toSet(),
    );

    final modifiableExtraSignersCredentialsAll = List.generate(
      txs.length,
      (index) => Set.of(txs[index].tx.body.requiredSigners?.signersBytes.map((e) => e.hexEncode()) ?? <String>[]),
    );

    // check for stake credentials/full hex stake address ; remove if we find any
    final extraSignersRequestedStakeAddressAll = modifiableExtraSignersCredentialsAll
        .map(
          (e) => e.removeFirstWhere((element) => element.contains(wallet.stakeAddress.credentials)),
        )
        .toList(growable: false);

    final pubKeyNativeScriptRequestedStakeAddressAll = modifiablePubKeyNativeScriptCredentialsAll
        .map(
          (e) => e.removeFirstWhere((element) => element.contains(wallet.stakeAddress.credentials)),
        )
        .toList(growable: false);

    final hasCertsForWalletStakeKeyAll = txs
        .map((e) => e.tx)
        .map((tx) => tx.body.certs.requiresStakeSignature(wallet.stakeAddress.credentialsBytes))
        .toList(growable: false);
    final hasCertsForColdKeyAll = txs
        .map((e) => e.tx)
        .map(
          (tx) => tx.body.certs.requiresCommitteeColdSignature(
            wallet.constitutionalCommiteeCold.value.credentialsBytes,
          ),
        )
        .toList(growable: false);

    final hasCertsOrVotesForDRepAll = txs
        .map((e) => e.tx)
        .map(
          (tx) =>
              tx.body.certs.requiresDrepSignature(wallet.drepId.value.credentialsBytes) ||
              tx.body.votingProcedures.requiresDrepSignature(wallet.drepId.value.credentialsBytes),
        )
        .toList(growable: false);
    final hasCommitteeHotVotesAll = txs
        .map((e) => e.tx)
        .map(
          (tx) => tx.body.votingProcedures.requiresCommitteeHotSignature(
            wallet.constitutionalCommiteeHot.value.credentialsBytes,
          ),
        )
        .toList(growable: false);
    final hasWithdrawalForWalletStakeKeyAll = txs
        .map((e) => e.tx)
        .map(
          (tx) =>
              tx.body.withdrawals?.any(
                (element) => element.stakeAddressBech32.bech32ToHex().endsWith(wallet.stakeAddress.credentials),
              ) ??
              false,
        )
        .toList(growable: false);

    final deriveAddressWorker = WalletTasksWorkerPool(
      concurrencySettings: const ConcurrencySettings(maxParallel: 2, maxWorkers: 2, minWorkers: 2),
    );

    try {
      await deriveAddressWorker.start();

      for (int i = 0; i < deriveMaxAddressCount; i++) {
        final paymentAddrForIndexFuture = deriveAddressWorker.execute(
          (worker) => worker.deriveAddressKit(wallet.hdWallet, networkId, i, Bip32KeyRole.payment),
        );
        final changeAddrForIndexFuture = deriveAddressWorker.execute(
          (worker) => worker.deriveAddressKit(wallet.hdWallet, networkId, i, Bip32KeyRole.change),
        );
        final paymentAddrForIndex = await paymentAddrForIndexFuture;
        final changeAddrForIndex = await changeAddrForIndexFuture;
        final bech32PaymentCredsForIndex = paymentAddrForIndex.address.credentials;
        final bech32ChangeCredsForIndex = changeAddrForIndex.address.credentials;

        modifiableSpendCredentialsAll.forEachIndexed((index, e) {
          if (e.remove(bech32PaymentCredsForIndex)) {
            signAddressesAll[index].add(paymentAddrForIndex);
          }
          if (e.remove(bech32ChangeCredsForIndex)) {
            signAddressesAll[index].add(changeAddrForIndex);
          }
        });

        modifiableExtraSignersCredentialsAll.forEachIndexed((index, e) {
          if (e.remove(bech32PaymentCredsForIndex)) {
            signAddressesAll[index].add(paymentAddrForIndex);
          }
          if (e.remove(bech32ChangeCredsForIndex)) {
            signAddressesAll[index].add(changeAddrForIndex);
          }
        });

        // Exact match: matching the blob as a substring of the address hex let a short (even empty) blob select a key
        modifiablePubKeyNativeScriptCredentialsAll.forEachIndexed((index, e) {
          if (e.remove(bech32PaymentCredsForIndex)) {
            signAddressesAll[index].add(paymentAddrForIndex);
          }

          if (e.remove(bech32ChangeCredsForIndex)) {
            signAddressesAll[index].add(changeAddrForIndex);
          }
        });

        if (modifiableSpendCredentialsAll.every((e) => e.isEmpty) &&
            modifiableExtraSignersCredentialsAll.every((e) => e.isEmpty) &&
            modifiablePubKeyNativeScriptCredentialsAll.every((e) => e.isEmpty)) {
          break;
        }
      }
    } finally {
      deriveAddressWorker.stop();
    }

    if (modifiableSpendCredentialsAll.flattened.isNotEmpty) {
      throw SigningAddressNotFoundException(
        missingAddresses: modifiableSpendCredentialsAll.flattened.toSet(),
        searchedAddressesCount: deriveMaxAddressCount,
      );
    }

    final needsStakeAddrSigningAll = List.generate(
      txs.length,
      (index) =>
          hasCertsForWalletStakeKeyAll[index] ||
          hasWithdrawalForWalletStakeKeyAll[index] ||
          extraSignersRequestedStakeAddressAll[index] ||
          pubKeyNativeScriptRequestedStakeAddressAll[index],
    );

    needsStakeAddrSigningAll.forEachIndexed((index, needsStakeAddrSigning) {
      if (needsStakeAddrSigning) {
        signAddressesAll[index].add(hdWallet.stakeKeys.value);
      }
    });

    final needsConstitutionalCommitteeColdSignAll = List.generate(
      txs.length,
      (index) => hasCertsForColdKeyAll[index],
    );

    needsConstitutionalCommitteeColdSignAll.forEachIndexed((index, needsCommitteeColdSigning) {
      if (needsCommitteeColdSigning) {
        signAddressesAll[index].add(hdWallet.constitutionalCommitteeColdKeys.value);
      }
    });

    final needsConstitutionalCommitteeHotSignAll = List.generate(
      txs.length,
      (index) => hasCommitteeHotVotesAll[index],
    );

    needsConstitutionalCommitteeHotSignAll.forEachIndexed((index, needsCommitteeHotSigning) {
      if (needsCommitteeHotSigning) {
        signAddressesAll[index].add(hdWallet.constitutionalCommitteeHotKeys.value);
      }
    });

    final needsDRepIdSignAll = List.generate(
      txs.length,
      (index) => hasCertsOrVotesForDRepAll[index],
    );

    needsDRepIdSignAll.forEachIndexed((index, needsDRepIdSigning) {
      if (needsDRepIdSigning) {
        signAddressesAll[index].add(hdWallet.drepCredentialKeys.value);
      }
    });

    final txsAndSignatures = txs.mapIndexed((index, e) {
      final tx = e.tx;
      final Uint8List bodyHash = tx.body.blake2bHash256Hex().hexDecode();
      final vKeyWitnesses = signAddressesAll[index].map((signAddr) {
        final signedMessage = signAddr.signingKey.sign(bodyHash);

        final witness = WitnessVKey(
          vkey: signAddr.verifyKey.rawKey.toUint8List(),
          signature: signedMessage.signature.toUint8List(),
        );

        return witness;
      });

      final witness = WitnessSet(
        ivkeyWitnesses: ListWithCborType(
          vKeyWitnesses.toList(),
          CborLengthType.auto,
          null,
        ),
      );

      return TxAndSignature(
        tx: tx,
        txDiff: e.txDiff,
        utxosBeforeTx: e.utxosBeforeTx,
        signingAddressesRequired: e.signingAddressesRequired,
        nweSignatures: witness,
      );
    });

    return TxSignedBundle(
      txsData: txsAndSignatures.toList(growable: false),
      totalDiff: bundle.totalDiff,
      networkId: bundle.networkId,
      receiveAddressBech32: bundle.receiveAddressBech32,
    );
  }

  @SquadronMethod()
  @cardanoSignerMarshaler
  Future<CardanoSigner> findCardanoSigner(
    String xPubHex,
    String requestedSignerRaw,
    int deriveMaxAddressCount,
  ) async {
    final pubAccount = await CardanoPubAccountFactory.instanceSync.fromHexXPub(xPubHex);
    return WalletTasksSign.findCardanoSigner(
      pubAccount: pubAccount,
      requestedSignerRaw: requestedSignerRaw,
      deriveMaxAddressCount: deriveMaxAddressCount,
    );
  }

  @SquadronMethod()
  @dataSignatureMarshaler
  Future<DataSignature> signDataV2(
    @walletMarshaler CardanoWalletImpl wallet,
    String payloadHex,
    String requestedSignerRaw,
    int deriveMaxAddressCount,
  ) async {
    final Uint8List payloadBytes = payloadHex.hexDecode();

    // Note avoiding calling wallet.cardanoPubAccount() to keep the operation in current worker/isolate
    final pubAccount = await CardanoPubAccountFactory.instanceSync.fromBech32XPub(wallet.xPubBech32);
    final signer = await WalletTasksSign.findCardanoSigner(
      pubAccount: pubAccount,
      requestedSignerRaw: requestedSignerRaw,
      deriveMaxAddressCount: deriveMaxAddressCount,
    );
    final signingKeyPair = await WalletTasksSign.signerToSigningKeyPair(
      wallet: wallet,
      signer: signer,
    );

    final headers = SigningUtils.prepareCoseHeaders(
      requestedSignerBytes: signer.requestedSignerBytes,
      hashed: false,
    );

    final dataToSign = SigningUtils.prepareBytesToSign(
      headers: headers,
      payloadBytes: payloadBytes,
    );

    final SignedMessage signedMessage = signingKeyPair.signingKey.sign(dataToSign);

    final DataSignature dataSignature = SigningUtils.prepareDataSignature(
      verifyRawKeyBytes: signingKeyPair.verifyKey.rawKey.toUint8List(),
      headers: headers,
      payloadBytes: payloadBytes,
      signatureBytes: signedMessage.signature.toUint8List(),
    );

    return dataSignature;
  }
}

List<String> _credsFromNativeScripts(List<NativeScript> scripts) {
  final d = scripts.map(
    (e) => switch (e) {
      NativeScript_PubKey() => [e.blob.hexEncode()],
      NativeScript_All() => _credsFromNativeScripts(e.scripts),
      NativeScript_Any() => _credsFromNativeScripts(e.scripts),
      NativeScript_AtLeast() => _credsFromNativeScripts(e.scripts),
      NativeScript_RequireTimeAfter() => const <String>[],
      NativeScript_RequireTimeBefore() => const <String>[],
    },
  );

  return d.flattened.toList();
}

/// Throws [TransactionNotBoundToWalletNetworkException] unless [tx] is invalid on every network but [walletNetwork].
///
/// The ledger rejects a transaction whose body network id, any output address or any withdrawal reward address is for
/// another network, so one of them on the wallet network binds it there, and any of them on another network is
/// refused. A transaction with inputs but none of them could be submitted on any network and is refused too. One
/// without inputs spends nothing, and the ledger rejects it anyway (InputSetEmptyUTxO).
void _requireBoundToNetwork({required CardanoTransaction tx, required NetworkId walletNetwork}) {
  final body = tx.body;
  final txNetworks = {
    ?body.networkId,
    // Byron addresses do not carry the network in their header
    ...body.outputs
        .map((e) => e.address.value)
        .where((e) => CardanoAddress.getAddressType(e) != AddressType.byron)
        .map(CardanoAddress.getNetworkId),
    ...?body.withdrawals?.map((e) => CardanoAddress.getNetworkId(e.stakeAddressBech32.bech32Decode())),
  };
  final hasOtherNetwork = {walletNetwork, ...txNetworks}.length > 1;
  final hasUnboundInputs = body.inputs.data.isNotEmpty && txNetworks.isEmpty;
  if (hasOtherNetwork || hasUnboundInputs) {
    throw TransactionNotBoundToWalletNetworkException(
      txHash: body.blake2bHash256Hex(),
      walletNetwork: walletNetwork,
      txNetworks: txNetworks,
    );
  }
}

/// Thrown by `prepareTxsForSigning` and by transaction signing for a transaction that could be valid on a network
/// other than the wallet's.
///
/// Wallet keys are the same on every network, and the signer also signs with keys the transaction asks for (required
/// signers, native scripts, certificates, votes, withdrawals). A requester could hand a testnet wallet a body that
/// spends the user's mainnet UTxOs: they are not among the wallet's testnet UTxOs, so the summary shows nothing leaving
/// the wallet, yet the witness is valid on mainnet. A transaction with inputs but no network id, Shelley output or
/// withdrawal is refused too: on another network its inputs could fund deposits refunded to the requester.
class TransactionNotBoundToWalletNetworkException extends Error {
  /// Hex of the blake2b-256 hash of the transaction body.
  final String txHash;
  final NetworkId walletNetwork;

  /// Networks of the body network id, the Shelley output addresses and the withdrawal reward addresses; empty when the
  /// transaction has none of them.
  final Set<NetworkId> txNetworks;

  TransactionNotBoundToWalletNetworkException({
    required this.txHash,
    required this.walletNetwork,
    required this.txNetworks,
  });

  @override
  String toString() {
    final found = txNetworks.isEmpty
        ? "no network id, Shelley output or withdrawal"
        : "networks [${txNetworks.map((e) => e.name).join(", ")}]";
    return "Transaction [$txHash] is not bound to the wallet network [${walletNetwork.name}]: its body has $found. "
        "Wallet keys are the same on every network, so a signature for it could be used on another network";
  }
}

extension ListCertsX on Certificates? {
  bool requiresDrepSignature(Uint8List walletDRepCredentials) =>
      this?.certificates.any(
        (cert) => switch (cert) {
          Certificate_StakeRegistrationLegacy() => false,
          Certificate_StakeDeRegistrationLegacy() => false,
          Certificate_StakeDelegation() => false,
          Certificate_PoolRegistration() => false,
          Certificate_PoolRetirement() => false,
          Certificate_StakeRegistration() => false,
          Certificate_StakeDeRegistration() => false,
          Certificate_VoteDelegation() => false,
          Certificate_StakeVoteDelegation() => false,
          Certificate_StakeRegistrationDelegation() => false,
          Certificate_VoteRegistrationDelegation() => false,
          Certificate_StakeVoteRegistrationDelegation() => false,
          Certificate_AuthorizeCommitteeHot() => false,
          Certificate_ResignCommitteeCold() => false,
          Certificate_RegisterDRep() => const ListEquality().equals(
            cert.dRepCredential.vKeyHash,
            walletDRepCredentials,
          ),
          Certificate_UnregisterDRep() => const ListEquality().equals(
            cert.dRepCredential.vKeyHash,
            walletDRepCredentials,
          ),
          Certificate_UpdateDRep() => const ListEquality().equals(
            cert.dRepCredential.vKeyHash,
            walletDRepCredentials,
          ),
        },
      ) ??
      false;

  bool requiresStakeSignature(Uint8List walletStakeCredentials) =>
      this?.certificates.any(
        (cert) => switch (cert) {
          Certificate_StakeRegistrationLegacy() => cert.stakeCredential.vKeyHash.equalsDeep(walletStakeCredentials),
          Certificate_StakeDeRegistrationLegacy() => cert.stakeCredential.vKeyHash.equalsDeep(walletStakeCredentials),
          Certificate_StakeDelegation() => cert.stakeCredential.vKeyHash.equalsDeep(walletStakeCredentials),
          Certificate_PoolRegistration() => false,
          Certificate_PoolRetirement() => false,
          Certificate_StakeRegistration() => cert.stakeCredential.vKeyHash.equalsDeep(walletStakeCredentials),
          Certificate_StakeDeRegistration() => cert.stakeCredential.vKeyHash.equalsDeep(walletStakeCredentials),
          Certificate_VoteDelegation() => cert.stakeCredential.vKeyHash.equalsDeep(walletStakeCredentials),
          Certificate_StakeVoteDelegation() => cert.stakeCredential.vKeyHash.equalsDeep(walletStakeCredentials),
          Certificate_StakeRegistrationDelegation() => cert.stakeCredential.vKeyHash.equalsDeep(walletStakeCredentials),
          Certificate_VoteRegistrationDelegation() => cert.stakeCredential.vKeyHash.equalsDeep(walletStakeCredentials),
          Certificate_StakeVoteRegistrationDelegation() => cert.stakeCredential.vKeyHash.equalsDeep(
            walletStakeCredentials,
          ),
          Certificate_AuthorizeCommitteeHot() => false,
          Certificate_ResignCommitteeCold() => false,
          Certificate_RegisterDRep() => false,
          Certificate_UnregisterDRep() => false,
          Certificate_UpdateDRep() => false,
        },
      ) ??
      false;

  bool requiresCommitteeColdSignature(Uint8List walletCommitteeColdCredentials) =>
      this?.certificates.any(
        (cert) => switch (cert) {
          Certificate_AuthorizeCommitteeHot() => cert.committeeColdCredential.vKeyHash.equalsDeep(
            walletCommitteeColdCredentials,
          ),
          Certificate_ResignCommitteeCold() => cert.committeeColdCredential.vKeyHash.equalsDeep(
            walletCommitteeColdCredentials,
          ),
          Certificate_StakeRegistrationLegacy() => false,
          Certificate_StakeDeRegistrationLegacy() => false,
          Certificate_StakeDelegation() => false,
          Certificate_PoolRegistration() => false,
          Certificate_PoolRetirement() => false,
          Certificate_StakeRegistration() => false,
          Certificate_StakeDeRegistration() => false,
          Certificate_VoteDelegation() => false,
          Certificate_StakeVoteDelegation() => false,
          Certificate_StakeRegistrationDelegation() => false,
          Certificate_VoteRegistrationDelegation() => false,
          Certificate_StakeVoteRegistrationDelegation() => false,
          Certificate_RegisterDRep() => false,
          Certificate_UnregisterDRep() => false,
          Certificate_UpdateDRep() => false,
        },
      ) ??
      false;
}

extension VotingProceduresX on VotingProcedures? {
  bool requiresDrepSignature(Uint8List walletDRepCredentials) =>
      this?.voting.keys.any(
        (voter) => voter.vKeyHash.equalsDeep(walletDRepCredentials),
      ) ??
      false;

  bool requiresCommitteeHotSignature(Uint8List walletCommitteeHotCredentials) =>
      this?.voting.keys.any(
        (voter) => voter.vKeyHash.equalsDeep(walletCommitteeHotCredentials),
      ) ??
      false;
}

extension Uint8ListX on Uint8List? {
  bool equalsDeep(Uint8List? other) => const ListEquality().equals(this, other);
}
