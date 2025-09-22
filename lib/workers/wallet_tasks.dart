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
    minWorkers: 1,
    // Temporary fix for the issue with the worker pool where nested worker tasks get scheduled on the same worker
    // --- using maxParallel to 1 would cause a deadlock for nested worker tasks
    // --- [in squadrion 6.0.3]
    maxParallel: 4,
  ),
  // ignore: discarded_futures
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

    return CardanoWalletImpl(firstAddress: firstAddress, stakeAddress: stakeAddress, hdWallet: hdWallet);
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
      final txHash = tx.body.blake2bHash256Hex();

      final usedUtxosTxAndId = tx.body.inputs.data.map((e) => "${e.transactionHash}#${e.index}").toSet();
      final collateralUtxosTxAndId = tx.body.collateral?.data.map((e) => "${e.transactionHash}#${e.index}").toSet();

      final txUtxos = {...usedUtxosTxAndId, ...?collateralUtxosTxAndId};
      final Set<String> signatureAddresses = walletUtxosBeforeTx
          // find all wallet utxos used in this tx
          .where((e) => txUtxos.contains("${e.identifier.transactionHash}#${e.identifier.index}"))
          // get the wallet addresses needed to sign the used wallet utxos
          .map((e) => e.content.addressBytes.addressBase58Orbech32Encode())
          .toSet();

      final List<Utxo> notUsedUserUtxos = walletUtxosBeforeTx
          .where((e) => !usedUtxosTxAndId.contains("${e.identifier.transactionHash}#${e.identifier.index}"))
          .toList();
      final List<Utxo> generatedUserUtxos = tx.body.outputs
          .mapIndexed<Utxo?>(
            (utxoIndex, e) => e.addressBytes.addressBase58Orbech32Encode() != bech32Address
                ? null
                : Utxo(
                    identifier: CardanoTransactionInput(transactionHash: txHash, index: utxoIndex),
                    content: e,
                  ),
          )
          .nonNulls
          .toList();

      txsPreparedForSigning.add(
        TxPreparedForSigning(
          tx: tx,
          txDiff: tx.diff(
            receiveAddressBech32: bech32Address,
            walletUtxos: walletUtxosBeforeTx,
            drepCredential: drepCredential,
            constitutionalCommitteeColdCredential: constitutionalCommitteeColdCredential,
            constitutionalCommitteeHotCredential: constitutionalCommitteeHotCredential,
          ),
          utxosBeforeTx: walletUtxosBeforeTx,
          signingAddressesRequired: signatureAddresses,
        ),
      );

      // for next iteration, update the utxos
      walletUtxosBeforeTx = [...notUsedUserUtxos, ...generatedUserUtxos];
    }

    final txsTotalDiff = txsPreparedForSigning.reduceSafe(
      initialValue: Value.v0(lovelace: BigInt.zero),
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
        final hexPaymentAddrForIndex = paymentAddrForIndex.address.hexEncoded;
        final hexChangeAddrForIndex = changeAddrForIndex.address.hexEncoded;
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

        modifiablePubKeyNativeScriptCredentialsAll.forEachIndexed((index, e) {
          if (e.removeFirstWhere(hexPaymentAddrForIndex.contains)) {
            signAddressesAll[index].add(paymentAddrForIndex);
          }

          if (e.removeFirstWhere(hexChangeAddrForIndex.contains)) {
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

  @Deprecated("Use signDataV2 instead")
  @SquadronMethod()
  @dataSignatureMarshaler
  Future<DataSignature> signDataLegacy(
    @walletMarshaler CardanoWallet wallet,
    String payloadHex,
    String requestedSignerRaw,
    int deriveMaxAddressCount,
  ) async {
    // if it's a bech32, convert it to hex
    final requestedSignerHex = ["addr", "stake", "drep", "cc_hot", "cc_cold"].any(requestedSignerRaw.startsWith)
        ? requestedSignerRaw.bech32ToHex()
        : requestedSignerRaw;

    final hdWallet = (wallet as CardanoWalletImpl).hdWallet;
    final networkId = wallet.networkId;
    final Uint8List payloadBytes = payloadHex.hexDecode();

    ({Uint8List? keyId, ByteList requestedSigningAddressBytes, Bip32KeyPair signingKeyPair}) dataFromAddress(
      CardanoAddress requestedSigningAddress,
    ) {
      final Bip32KeyPair signingKeyPair = switch (requestedSigningAddress.addressType) {
        AddressType.reward => () {
          if (requestedSigningAddress.hexEncoded == wallet.stakeAddress.hexEncoded) {
            return hdWallet.stakeKeys.value;
          } else {
            throw SigningAddressNotFoundException(
              missingAddresses: {requestedSigningAddress.bech32Encoded},
              searchedAddressesCount: 1,
            );
          }
        }(),
        AddressType.base => () {
          for (int i = 0; i < deriveMaxAddressCount; i++) {
            final paymentAddrForIndex = hdWallet.deriveBaseAddressKit(
              index: i,
              role: Bip32KeyRole.payment,
              networkId: networkId,
            );
            final changeAddrForIndex = hdWallet.deriveBaseAddressKit(
              index: i,
              role: Bip32KeyRole.change,
              networkId: networkId,
            );
            if (paymentAddrForIndex.address == requestedSigningAddress) {
              return paymentAddrForIndex;
            } else if (changeAddrForIndex.address == requestedSigningAddress) {
              return changeAddrForIndex;
            }
          }

          // if not found in for loop, throw
          throw SigningAddressNotFoundException(
            missingAddresses: {requestedSigningAddress.bech32Encoded},
            searchedAddressesCount: deriveMaxAddressCount,
          );
        }(),
        AddressType.pointer ||
        AddressType.enterprise ||
        AddressType.byron => throw UnexpectedSigningAddressTypeException(
          hexAddress: requestedSignerRaw,
          type: requestedSigningAddress.addressType,
          signingContext: "When signing payload message",
        ),
      };

      return (
        // not sure when/if we ever need keyId
        // keyId: signingKeyPair.verifyKey.rawKey.toUint8List(), // raw key (no hashing)
        keyId: null,
        requestedSigningAddressBytes: requestedSigningAddress.bytes, // type and network header + hashed key
        signingKeyPair: signingKeyPair, // pub+priv keys for signing
      );
    }

    ({Uint8List? keyId, ByteList requestedSigningAddressBytes, Bip32KeyPair signingKeyPair}) dataFromDrepIdOrCreds(
      String drepIdOrCredsHex,
    ) {
      final walletDrepCredentials = wallet.drepId.value.credentialsHex;
      if (!drepIdOrCredsHex.endsWith(walletDrepCredentials)) {
        throw SigningAddressNotFoundException(
          missingAddresses: {requestedSignerRaw},
          searchedAddressesCount: 1,
        );
      }

      final Bip32KeyPair signingKeyPair = hdWallet.drepCredentialKeys.value;
      return (
        // not sure when/if we ever need keyId
        // keyId: signingKeyPair.verifyKey.rawKey.toUint8List(), // (drep) key with no hashing
        keyId: null,
        requestedSigningAddressBytes: ByteList(wallet.drepId.value.credentialsBytes), // hashed key WITHOUT HEADER
        signingKeyPair: signingKeyPair, // pub+priv keys for signing
      );
    }

    final data = switch (requestedSignerHex.length) {
      // This is used for dRep (CIP-95)
      //
      // NOTE: In the future, we can maybe also check against any other payment/change/stake/cc credentials
      //   (since the 56 bytes creds do not include the header which tells us the creds type)
      56 => dataFromDrepIdOrCreds(requestedSignerHex),
      // 58 or 114 is the length of the stake or receive address hex
      58 => () {
        final requestedSignerBytes = requestedSignerHex.hexDecode();
        final headerBytes = requestedSignerBytes[0];
        return headerBytes & 0x0f > 1
            ? dataFromDrepIdOrCreds(requestedSignerHex)
            : dataFromAddress(CardanoAddress.fromHexString(requestedSignerHex));
      }(),
      114 => dataFromAddress(CardanoAddress.fromHexString(requestedSignerHex)),
      _ => throw SigningAddressNotValidException(
        hexInvalidAddressOrCredential: requestedSignerHex,
        signingContext: "When signing payload message",
      ),
    };

    final headers = CoseHeaders(
      protectedHeader: CoseProtectedHeaderMap(
        bytes: CoseHeaderMap(
          algorithmId: const CborSmallInt(ALG_EdDSA),
          keyId: data.keyId,
          otherHeaders: CborMap.of({
            CborString(ADDRESS_KEY): CborBytes(data.requestedSigningAddressBytes),
          }),
        ).serializeAsBytes(),
      ),
      unprotectedHeader: CoseHeaderMap(hashed: false, otherHeaders: CborMap.of({})),
    );

    final sigStructure = CoseSigStructure.fromSign1(
      bodyProtected: headers.protectedHeader,
      payload: payloadBytes,
    );
    final dataToSign = sigStructure.serializeAsBytes();

    final SignedMessage signedMessage = data.signingKeyPair.signingKey.sign(dataToSign);

    final coseSign1 = CoseSign1(
      headers: headers,
      payload: payloadBytes,
      signature: signedMessage.signature.toUint8List(),
    );

    final coseKey = CoseKey(keyId: data.signingKeyPair.verifyKey.rawKey.toUint8List());

    return DataSignature(
      coseKeyHex: coseKey.serializeAsBytes().hexEncode(),
      coseSignHex: coseSign1.serializeAsBytes().hexEncode(),
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

extension ListCertsX on List<Certificate>? {
  bool requiresDrepSignature(Uint8List walletDRepCredentials) =>
      this?.any(
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
      this?.any(
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
      this?.any(
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
