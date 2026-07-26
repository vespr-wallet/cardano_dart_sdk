import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "../../workers/wallet_tasks.dart";
import "../models/tx_signing_preparation.dart";

class SigningUtils {
  const SigningUtils._();

  /// Prepares a signing bundle using the supplied wallet UTxOs.
  ///
  /// Prefer [prepareTxsForSigningWithUtxoOwnership] when preparing an untrusted transaction. This compatibility API
  /// cannot report whether non-wallet inputs have known owners.
  @Deprecated(
    "Use prepareTxsForSigningWithUtxoOwnership instead. "
    "prepareTxsForSigning will be removed in a future release.",
  )
  static Future<TxSigningBundle> prepareTxsForSigning({
    required List<CardanoTransaction> txs,
    required List<Utxo> walletUtxos,
    required String walletReceiveAddressBech32,
    required String drepCredential,
    required String constitutionalCommitteeColdCredential,
    required String constitutionalCommitteeHotCredential,
    required NetworkId networkId,
  }) => Future.sync(() {
    final txSnapshot = _snapshotTransactions(txs);
    final walletUtxoSnapshot = _snapshotUtxos(walletUtxos);
    final inspection = _inspectTransactionBatch(
      txs: txSnapshot,
      walletUtxos: walletUtxoSnapshot,
      utxoAddresses: const {},
      additionalUserOwnedAddresses: const {},
      walletReceiveAddressBech32: walletReceiveAddressBech32,
    );

    return cardanoWorker.prepareTxsForSigningImpl(
      walletReceiveAddressBech32,
      drepCredential,
      constitutionalCommitteeColdCredential,
      constitutionalCommitteeHotCredential,
      networkId,
      txSnapshot,
      walletUtxoSnapshot,
      inspection.userOwnedAddresses,
    );
  });

  /// Prepares a signing bundle and classifies every input UTxO by ownership.
  ///
  /// [walletUtxos] must contain the complete outputs for known user-owned spending and collateral inputs.
  /// [utxoAddresses] resolves other UTxO ids to trusted source addresses. Missing entries are reported as
  /// [UnresolvedUtxo] and retain external semantics for the wallet value diff. [additionalUserOwnedAddresses]
  /// declares wallet addresses which do not currently have an entry in [walletUtxos].
  static Future<TxSigningPreparation> prepareTxsForSigningWithUtxoOwnership({
    required List<CardanoTransaction> txs,
    required List<Utxo> walletUtxos,
    required Map<UtxoId, String> utxoAddresses,
    required Set<String> additionalUserOwnedAddresses,
    required String walletReceiveAddressBech32,
    required String drepCredential,
    required String constitutionalCommitteeColdCredential,
    required String constitutionalCommitteeHotCredential,
    required NetworkId networkId,
  }) => Future.sync(() {
    final txSnapshot = _snapshotTransactions(txs);
    final walletUtxoSnapshot = _snapshotUtxos(walletUtxos);
    final utxoAddressSnapshot = Map<UtxoId, String>.unmodifiable(utxoAddresses);
    final additionalUserOwnedAddressSnapshot = Set<String>.unmodifiable(additionalUserOwnedAddresses);
    final inspection = _inspectTransactionBatch(
      txs: txSnapshot,
      walletUtxos: walletUtxoSnapshot,
      utxoAddresses: utxoAddressSnapshot,
      additionalUserOwnedAddresses: additionalUserOwnedAddressSnapshot,
      walletReceiveAddressBech32: walletReceiveAddressBech32,
    );

    return cardanoWorker
        .prepareTxsForSigningImpl(
          walletReceiveAddressBech32,
          drepCredential,
          constitutionalCommitteeColdCredential,
          constitutionalCommitteeHotCredential,
          networkId,
          txSnapshot,
          walletUtxoSnapshot,
          inspection.userOwnedAddresses,
        )
        .then(
          (signingBundle) => TxSigningPreparation(
            signingBundle: signingBundle,
            transactions: inspection.transactions,
          ),
        );
  });

  static CoseHeaders prepareCoseHeaders({
    required Uint8List requestedSignerBytes, // requested signer (address/drep/etc bytes)
    required bool hashed,
  }) => CoseHeaders(
    protectedHeader: CoseProtectedHeaderMap(
      bytes: CoseHeaderMap(
        algorithmId: const CborSmallInt(ALG_EdDSA),
        keyId: null,
        otherHeaders: CborMap.of({
          CborString(ADDRESS_KEY): CborBytes(requestedSignerBytes),
        }),
      ).serializeAsBytes(),
    ),
    unprotectedHeader: CoseHeaderMap(
      hashed: hashed,
      otherHeaders: CborMap.of({}),
    ),
  );

  static Uint8List prepareBytesToSign({
    required CoseHeaders headers,
    required Uint8List payloadBytes, // if hashed, it should be the hashed payload
  }) => CoseSigStructure.fromSign1(
    bodyProtected: headers.protectedHeader,
    payload: payloadBytes,
  ).serializeAsBytes();

  static DataSignature prepareDataSignature({
    required Uint8List verifyRawKeyBytes,
    required CoseHeaders headers,
    required Uint8List payloadBytes, // if hashed, it should be the hashed payload
    required Uint8List signatureBytes,
  }) {
    final coseKey = CoseKey(keyId: verifyRawKeyBytes);
    final coseSign1 = CoseSign1(
      headers: headers,
      payload: payloadBytes,
      signature: signatureBytes,
    );
    return DataSignature(
      coseKeyHex: coseKey.serializeAsBytes().hexEncode(),
      coseSignHex: coseSign1.serializeAsBytes().hexEncode(),
    );
  }
}

final class _BatchInspection {
  const _BatchInspection({required this.userOwnedAddresses, required this.transactions});

  final List<String> userOwnedAddresses;
  final List<TxUtxoTransparency> transactions;
}

final class _ResolvedUtxo {
  const _ResolvedUtxo({required this.address, required this.isUserOwned, required this.hasContent});

  final String address;
  final bool isUserOwned;
  final bool hasContent;
}

_BatchInspection _inspectTransactionBatch({
  required List<CardanoTransaction> txs,
  required List<Utxo> walletUtxos,
  required Map<UtxoId, String> utxoAddresses,
  required Set<String> additionalUserOwnedAddresses,
  required String walletReceiveAddressBech32,
}) {
  final walletUtxosById = <UtxoId, Utxo>{};
  for (final utxo in walletUtxos) {
    final id = UtxoId.fromInput(utxo.identifier);
    if (walletUtxosById.containsKey(id)) {
      throw InvalidTransactionBatchException("Wallet UTxO $id was supplied more than once.");
    }
    walletUtxosById[id] = utxo;
  }

  final canonicalReceiveAddress = _canonicalAddress(walletReceiveAddressBech32);
  final userOwnedAddressByHex = <String, String>{
    _addressHex(canonicalReceiveAddress): canonicalReceiveAddress,
  };
  for (final address in additionalUserOwnedAddresses) {
    final canonicalAddress = _canonicalAddress(address);
    userOwnedAddressByHex[_addressHex(canonicalAddress)] = canonicalAddress;
  }
  for (final utxo in walletUtxos) {
    final address = utxo.content.address.base58OrBech32Value;
    userOwnedAddressByHex[utxo.content.address.hexValue] = address;
  }

  final canonicalUtxoAddresses = <UtxoId, String>{};
  for (final entry in utxoAddresses.entries) {
    canonicalUtxoAddresses[entry.key] = _canonicalAddress(entry.value);
  }
  for (final entry in walletUtxosById.entries) {
    final resolvedAddress = canonicalUtxoAddresses[entry.key];
    if (resolvedAddress != null && _addressHex(resolvedAddress) != entry.value.content.address.hexValue) {
      throw InvalidTransactionBatchException(
        "The resolved address for wallet UTxO ${entry.key} does not match its output address.",
      );
    }
  }

  final transactionIds = txs.map((tx) => tx.body.blake2bHash256Hex()).toList(growable: false);
  final transactionIndexById = <String, int>{};
  for (var index = 0; index < transactionIds.length; index++) {
    final transactionId = transactionIds[index];
    final previousIndex = transactionIndexById[transactionId];
    if (previousIndex != null) {
      throw InvalidTransactionBatchException(
        "Transactions $previousIndex and $index have the same transaction id $transactionId.",
      );
    }
    transactionIndexById[transactionId] = index;
  }

  final generatedUtxosByTransaction = <Map<UtxoId, String>>[];
  for (var index = 0; index < txs.length; index++) {
    final tx = txs[index];
    final transactionId = transactionIds[index];
    final generatedUtxos = <UtxoId, String>{};
    if (tx.isValidDi) {
      for (var outputIndex = 0; outputIndex < tx.body.outputs.length; outputIndex++) {
        generatedUtxos[UtxoId(transactionHash: transactionId, index: outputIndex)] =
            tx.body.outputs[outputIndex].address.base58OrBech32Value;
      }
    } else {
      final collateralReturn = tx.body.collateralReturn;
      if (collateralReturn != null) {
        generatedUtxos[UtxoId(transactionHash: transactionId, index: tx.body.outputs.length)] =
            collateralReturn.address.base58OrBech32Value;
      }
    }
    generatedUtxosByTransaction.add(generatedUtxos);
  }

  for (final id in walletUtxosById.keys) {
    if (transactionIndexById.containsKey(id.transactionHash)) {
      throw InvalidTransactionBatchException("Wallet UTxO $id collides with an output from this batch.");
    }
  }

  final availableUtxos = <UtxoId, _ResolvedUtxo>{};
  for (final entry in canonicalUtxoAddresses.entries) {
    if (transactionIndexById.containsKey(entry.key.transactionHash)) continue;
    availableUtxos[entry.key] = _ResolvedUtxo(
      address: entry.value,
      isUserOwned: userOwnedAddressByHex.containsKey(_addressHex(entry.value)),
      hasContent: false,
    );
  }
  for (final entry in walletUtxosById.entries) {
    availableUtxos[entry.key] = _ResolvedUtxo(
      address: entry.value.content.address.base58OrBech32Value,
      isUserOwned: true,
      hasContent: true,
    );
  }

  final consumedUtxos = <UtxoId>{};
  final transactions = <TxUtxoTransparency>[];
  for (var transactionIndex = 0; transactionIndex < txs.length; transactionIndex++) {
    final tx = txs[transactionIndex];
    final spendingInputs = tx.body.inputs.data.map(UtxoId.fromInput).toList(growable: false);
    final collateralInputs = tx.body.collateral?.data.map(UtxoId.fromInput).toList(growable: false) ?? const <UtxoId>[];
    final referenceInputs =
        tx.body.referenceInputs?.data.map(UtxoId.fromInput).toList(growable: false) ?? const <UtxoId>[];

    _rejectDuplicateInputs(spendingInputs, transactionIndex: transactionIndex, role: "spending");
    _rejectDuplicateInputs(collateralInputs, transactionIndex: transactionIndex, role: "collateral");
    _rejectDuplicateInputs(referenceInputs, transactionIndex: transactionIndex, role: "reference");

    final spendingInputSet = spendingInputs.toSet();
    final spendingAndReferenceOverlap = spendingInputSet.intersection(referenceInputs.toSet());
    if (spendingAndReferenceOverlap.isNotEmpty) {
      throw InvalidTransactionBatchException(
        "Transaction $transactionIndex uses ${spendingAndReferenceOverlap.first} as both a spending and reference input.",
      );
    }

    final allInputs = <UtxoId>{...spendingInputs, ...collateralInputs, ...referenceInputs};
    final valueOrSignatureInputs = <UtxoId>{...spendingInputs, ...collateralInputs};
    final ownership = <UtxoId, UtxoOwnership>{};
    for (final id in allInputs) {
      if (consumedUtxos.contains(id)) {
        throw InvalidTransactionBatchException(
          "Transaction $transactionIndex references UTxO $id after it was consumed earlier in the batch.",
        );
      }

      final producerIndex = transactionIndexById[id.transactionHash];
      if (producerIndex != null) {
        if (producerIndex >= transactionIndex) {
          throw InvalidTransactionBatchException(
            "Transaction $transactionIndex references UTxO $id before it is created.",
          );
        }
        if (!generatedUtxosByTransaction[producerIndex].containsKey(id)) {
          throw InvalidTransactionBatchException(
            "Transaction $transactionIndex references UTxO $id, but transaction $producerIndex does not create it.",
          );
        }
      }

      final resolvedUtxo = availableUtxos[id];
      if (resolvedUtxo == null) {
        ownership[id] = const UnresolvedUtxo();
        continue;
      }
      if (resolvedUtxo.isUserOwned) {
        if (!resolvedUtxo.hasContent && valueOrSignatureInputs.contains(id)) {
          throw InvalidTransactionBatchException(
            "User-owned UTxO $id is missing its full output, so its value and signing key cannot be verified.",
          );
        }
        ownership[id] = UserOwnedUtxo(address: resolvedUtxo.address);
      } else {
        ownership[id] = ExternalUtxo(address: resolvedUtxo.address);
      }
    }

    transactions.add(
      TxUtxoTransparency(
        transactionIndex: transactionIndex,
        transactionId: transactionIds[transactionIndex],
        utxoOwnership: ownership,
      ),
    );

    final inputsConsumedByTransaction = tx.isValidDi ? spendingInputSet : collateralInputs.toSet();
    for (final id in inputsConsumedByTransaction) {
      consumedUtxos.add(id);
      availableUtxos.remove(id);
    }

    for (final entry in generatedUtxosByTransaction[transactionIndex].entries) {
      if (consumedUtxos.contains(entry.key) || availableUtxos.containsKey(entry.key)) {
        throw InvalidTransactionBatchException("Generated UTxO ${entry.key} collides with another UTxO.");
      }
      final suppliedAddress = canonicalUtxoAddresses[entry.key];
      if (suppliedAddress != null && _addressHex(suppliedAddress) != _addressHex(entry.value)) {
        throw InvalidTransactionBatchException(
          "The resolved address for generated UTxO ${entry.key} does not match its output address.",
        );
      }
      final address = _canonicalAddress(entry.value);
      availableUtxos[entry.key] = _ResolvedUtxo(
        address: address,
        isUserOwned: userOwnedAddressByHex.containsKey(_addressHex(address)),
        hasContent: true,
      );
    }
  }

  return _BatchInspection(
    userOwnedAddresses: List.unmodifiable(userOwnedAddressByHex.values),
    transactions: List.unmodifiable(transactions),
  );
}

void _rejectDuplicateInputs(List<UtxoId> inputs, {required int transactionIndex, required String role}) {
  final uniqueInputs = <UtxoId>{};
  for (final input in inputs) {
    if (!uniqueInputs.add(input)) {
      throw InvalidTransactionBatchException(
        "Transaction $transactionIndex contains duplicate $role input $input.",
      );
    }
  }
}

String _canonicalAddress(String address) => Address.fromBase58OrBech32(address).base58OrBech32Value;

String _addressHex(String address) => Address.fromBase58OrBech32(address).hexValue;

List<CardanoTransaction> _snapshotTransactions(List<CardanoTransaction> txs) => List.unmodifiable(
  txs.map((tx) => CardanoTransaction.deserializeBytes(tx.serializeAsBytes())),
);

List<Utxo> _snapshotUtxos(List<Utxo> utxos) => List.unmodifiable(
  utxos.map((utxo) => Utxo.deserializeBytes(utxo.serializeAsBytes())),
);
