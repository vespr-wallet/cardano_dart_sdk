// ignore_for_file: deprecated_member_use_from_same_package

import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/cardano_flutter_sdk.dart";
import "package:test/test.dart";

import "test_utils/fixtures.dart";

const _walletAddress =
    "addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx";
const _secondaryWalletAddress =
    "addr1qyfs44hfdvrwxk30x0u28t8mezf4620jkecfkeqh4j2gusf8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qxz45yy";
const _credential = "00000000000000000000000000000000000000000000000000000000";

void main() {
  group("prepareTxsForSigning review regressions", () {
    test("matches UTxO references independently of CBOR metadata", () async {
      final utxo = _utxo(hashByte: 1, index: 0, address: _walletAddress, lovelace: 10);
      final inputWithDifferentCborMetadata = CardanoTransactionInput(
        transactionHash: TransactionHash(
          value: utxo.identifier.transactionHash.value,
          cborTags: const [42],
        ),
        index: utxo.identifier.index,
      );
      final tx = _tx(inputs: [inputWithDifferentCborMetadata], outputs: [_output(_walletAddress, 8)]);

      final bundle = await _prepare(txs: [tx], walletUtxos: [utxo]);

      expect(bundle.txsData.single.signingAddressesRequired, {_walletAddress});
      expect(bundle.txsData.single.txDiff.usedUtxos, [utxo]);
      expect(bundle.totalDiff.lovelace, BigInt.from(-2).toCborInt());
    });

    test("tracks chained outputs sent to every known wallet address", () async {
      final input = _utxo(hashByte: 2, index: 0, address: _walletAddress, lovelace: 10);
      final secondaryAddressMarker = _utxo(
        hashByte: 3,
        index: 0,
        address: _secondaryWalletAddress,
        lovelace: 5,
      );
      final tx1 = _tx(inputs: [input.identifier], outputs: [_output(_secondaryWalletAddress, 8)]);
      final tx1Output = CardanoTransactionInput(
        transactionHash: TransactionHash.fromHex(tx1.body.blake2bHash256Hex()),
        index: 0,
      );
      final tx2 = _tx(inputs: [tx1Output], outputs: [_output(_walletAddress, 1)]);

      final bundle = await _prepare(txs: [tx1, tx2], walletUtxos: [input, secondaryAddressMarker]);

      expect(bundle.txsData[0].txDiff.diff.lovelace, BigInt.from(-2).toCborInt());
      expect(bundle.txsData[1].txDiff.diff.lovelace, BigInt.from(-7).toCborInt());
      expect(bundle.totalDiff.lovelace, BigInt.from(-9).toCborInt());
      expect(bundle.txsData[1].signingAddressesRequired, {_secondaryWalletAddress});
    });

    test("rejects a UTxO consumed twice by a valid batch", () async {
      final input = _utxo(hashByte: 4, index: 0, address: _walletAddress, lovelace: 10);
      final tx1 = _tx(inputs: [input.identifier], outputs: [_output(_walletAddress, 8)]);
      final tx2 = _tx(inputs: [input.identifier], outputs: [_output(_walletAddress, 7)]);

      await expectLater(
        _prepare(txs: [tx1, tx2], walletUtxos: [input]),
        throwsA(isA<InvalidTransactionBatchException>()),
      );
    });

    test("rejects duplicate spending inputs within one transaction", () async {
      final input = _utxo(hashByte: 5, index: 0, address: _walletAddress, lovelace: 10);
      final tx = _tx(inputs: [input.identifier, input.identifier], outputs: [_output(_walletAddress, 8)]);

      await expectLater(
        _prepare(txs: [tx], walletUtxos: [input]),
        throwsA(isA<InvalidTransactionBatchException>()),
      );
    });

    test("applies collateral state transition for an invalid phase-2 transaction", () async {
      final normalInput = _utxo(hashByte: 6, index: 0, address: _walletAddress, lovelace: 10);
      final collateralInput = _utxo(hashByte: 7, index: 0, address: _walletAddress, lovelace: 4);
      final invalidTx = _tx(
        inputs: [normalInput.identifier],
        collateral: [collateralInput.identifier],
        outputs: [_output(_walletAddress, 7)],
        collateralReturn: _output(_walletAddress, 1),
        isValid: false,
      );
      final collateralReturnInput = CardanoTransactionInput(
        transactionHash: TransactionHash.fromHex(invalidTx.body.blake2bHash256Hex()),
        index: invalidTx.body.outputs.length,
      );
      final nextTx = _tx(
        inputs: [normalInput.identifier, collateralReturnInput],
        outputs: [_output(_walletAddress, 2)],
      );

      final bundle = await _prepare(
        txs: [invalidTx, nextTx],
        walletUtxos: [normalInput, collateralInput],
      );

      expect(bundle.txsData[0].txDiff.diff.lovelace, BigInt.from(-3).toCborInt());
      expect(bundle.txsData[0].txDiff.usedUtxos, [collateralInput]);
      expect(bundle.txsData[1].txDiff.diff.lovelace, BigInt.from(-9).toCborInt());
      expect(bundle.txsData[1].signingAddressesRequired, {_walletAddress});
      expect(
        bundle.txsData[1].utxosBeforeTx.map((utxo) => _utxoKey(utxo.identifier)),
        containsAll({_utxoKey(normalInput.identifier), _utxoKey(collateralReturnInput)}),
      );
    });

    test("preserves invalid collateral precision beyond the JavaScript safe integer range", () async {
      final collateralAmount = BigInt.parse("31718971375682855");
      final returnAmount = BigInt.parse("10000000000000000");
      final normalInput = _utxo(hashByte: 25, index: 0, address: _walletAddress, lovelace: 10);
      final collateralInput = Utxo(
        identifier: _input(hashByte: 26),
        content: _bigOutput(_walletAddress, collateralAmount),
      );
      final tx = _tx(
        inputs: [normalInput.identifier],
        collateral: [collateralInput.identifier],
        outputs: [_output(_walletAddress, 7)],
        collateralReturn: _bigOutput(_walletAddress, returnAmount),
        isValid: false,
      );

      final bundle = await _prepare(txs: [tx], walletUtxos: [normalInput, collateralInput]);

      expect(bundle.totalDiff.lovelace, (returnAmount - collateralAmount).toCborInt());
    });

    test("reports user-owned, external, and unresolved UTxOs separately", () async {
      final userInput = _utxo(hashByte: 8, index: 0, address: _walletAddress, lovelace: 10);
      final externalSpendingInput = _input(hashByte: 9);
      final externalCollateralInput = _input(hashByte: 31);
      final unresolvedReferenceInput = _input(hashByte: 10);
      final unresolvedSpendingInput = _input(hashByte: 28);
      final tx = _tx(
        inputs: [userInput.identifier, externalSpendingInput, unresolvedSpendingInput],
        collateral: [externalCollateralInput],
        referenceInputs: [unresolvedReferenceInput],
        outputs: [_output(_walletAddress, 7)],
      );

      final preparation = await SigningUtils.prepareTxsForSigningWithUtxoOwnership(
        txs: [tx],
        walletUtxos: [userInput],
        utxoAddresses: {
          UtxoId.fromInput(externalSpendingInput): _secondaryWalletAddress,
          UtxoId.fromInput(externalCollateralInput): _secondaryWalletAddress,
        },
        additionalUserOwnedAddresses: const {},
        walletReceiveAddressBech32: _walletAddress,
        drepCredential: _credential,
        constitutionalCommitteeColdCredential: _credential,
        constitutionalCommitteeHotCredential: _credential,
        networkId: NetworkId.mainnet,
      );
      final transparency = preparation.transactions.single;

      expect(transparency.utxoOwnership[UtxoId.fromInput(userInput.identifier)], isA<UserOwnedUtxo>());
      expect(transparency.utxoOwnership[UtxoId.fromInput(externalSpendingInput)], isA<ExternalUtxo>());
      expect(transparency.utxoOwnership[UtxoId.fromInput(externalCollateralInput)], isA<ExternalUtxo>());
      expect(transparency.utxoOwnership[UtxoId.fromInput(unresolvedReferenceInput)], isA<UnresolvedUtxo>());
      expect(transparency.utxoOwnership[UtxoId.fromInput(unresolvedSpendingInput)], isA<UnresolvedUtxo>());
      expect(transparency.isFullyTransparent, isFalse);
      expect(transparency.unresolvedUtxos, {
        UtxoId.fromInput(unresolvedReferenceInput),
        UtxoId.fromInput(unresolvedSpendingInput),
      });
      expect(preparation.isFullyTransparent, isFalse);
      expect(
        transparency.transparencyWarning,
        "This transaction is not fully transparent due to unresolved UTxO(s).",
      );
      expect(preparation.signingBundle.totalDiff.lovelace, BigInt.from(-3).toCborInt());
      expect(preparation.signingBundle.txsData.single.signingAddressesRequired, {_walletAddress});
    });

    test("snapshots mutable caller collections before worker dispatch", () async {
      final input = _utxo(hashByte: 29, index: 0, address: _walletAddress, lovelace: 10);
      final tx = _tx(inputs: [input.identifier], outputs: [_output(_walletAddress, 8)]);
      final txs = <CardanoTransaction>[tx];
      final walletUtxos = <Utxo>[input];

      final preparationFuture = _prepare(txs: txs, walletUtxos: walletUtxos);
      txs.clear();
      walletUtxos.clear();
      final bundle = await preparationFuture;

      expect(bundle.txsData, hasLength(1));
      expect(bundle.txsData.single.txDiff.usedUtxos, [input]);
      expect(bundle.totalDiff.lovelace, BigInt.from(-2).toCborInt());
    });

    test("canonicalizes stale cached transaction hashes before chaining", () async {
      final input = _utxo(hashByte: 30, index: 0, address: _walletAddress, lovelace: 10);
      final originalTx = _tx(inputs: [input.identifier], outputs: [_output(_walletAddress, 8)]);
      final txWithStaleHash = originalTx.copyWith(
        body: originalTx.body.copyWith(
          blake2bHash256: Blake2bHash256.passed(blake2bHash256: List.filled(32, "ff").join()),
        ),
      );
      final actualOutput = CardanoTransactionInput(
        transactionHash: TransactionHash(value: txWithStaleHash.body.computeBlake2bHash256()),
        index: 0,
      );
      final nextTx = _tx(inputs: [actualOutput], outputs: [_output(_walletAddress, 1)]);

      final bundle = await _prepare(txs: [txWithStaleHash, nextTx], walletUtxos: [input]);

      expect(bundle.txsData[1].txDiff.diff.lovelace, BigInt.from(-7).toCborInt());
      expect(bundle.txsData[1].signingAddressesRequired, {_walletAddress});
    });

    test("rejects an unresolved external UTxO consumed twice", () async {
      final unresolvedInput = _input(hashByte: 11);
      final tx1 = _tx(inputs: [unresolvedInput], outputs: [_output(_walletAddress, 1)]);
      final tx2 = _tx(inputs: [unresolvedInput], outputs: [_output(_walletAddress, 2)]);

      await expectLater(
        _prepare(txs: [tx1, tx2], walletUtxos: const []),
        throwsA(isA<InvalidTransactionBatchException>()),
      );
    });

    test("allows successful collateral to be consumed by a later transaction", () async {
      final spendingInput = _utxo(hashByte: 12, index: 0, address: _walletAddress, lovelace: 10);
      final collateralInput = _utxo(hashByte: 13, index: 0, address: _walletAddress, lovelace: 4);
      final tx1 = _tx(
        inputs: [spendingInput.identifier],
        collateral: [collateralInput.identifier],
        outputs: [_output(_walletAddress, 8)],
      );
      final tx2 = _tx(inputs: [collateralInput.identifier], outputs: [_output(_walletAddress, 3)]);

      final bundle = await _prepare(txs: [tx1, tx2], walletUtxos: [spendingInput, collateralInput]);

      expect(bundle.txsData[1].txDiff.usedUtxos, [collateralInput]);
      expect(bundle.txsData[1].signingAddressesRequired, {_walletAddress});
    });

    test("allows an invalid transaction's regular input to be consumed later", () async {
      final spendingInput = _utxo(hashByte: 14, index: 0, address: _walletAddress, lovelace: 10);
      final collateralInput = _utxo(hashByte: 15, index: 0, address: _walletAddress, lovelace: 4);
      final invalidTx = _tx(
        inputs: [spendingInput.identifier],
        collateral: [collateralInput.identifier],
        outputs: [_output(_walletAddress, 8)],
        isValid: false,
      );
      final nextTx = _tx(inputs: [spendingInput.identifier], outputs: [_output(_walletAddress, 3)]);

      final bundle = await _prepare(
        txs: [invalidTx, nextTx],
        walletUtxos: [spendingInput, collateralInput],
      );

      expect(bundle.txsData[1].txDiff.usedUtxos, [spendingInput]);
      expect(bundle.txsData[1].signingAddressesRequired, {_walletAddress});
    });

    test("rejects collateral consumed by an invalid transaction when reused later", () async {
      final spendingInput = _utxo(hashByte: 16, index: 0, address: _walletAddress, lovelace: 10);
      final collateralInput = _utxo(hashByte: 17, index: 0, address: _walletAddress, lovelace: 4);
      final invalidTx = _tx(
        inputs: [spendingInput.identifier],
        collateral: [collateralInput.identifier],
        outputs: [_output(_walletAddress, 8)],
        isValid: false,
      );
      final nextTx = _tx(inputs: [collateralInput.identifier], outputs: [_output(_walletAddress, 3)]);

      await expectLater(
        _prepare(txs: [invalidTx, nextTx], walletUtxos: [spendingInput, collateralInput]),
        throwsA(isA<InvalidTransactionBatchException>()),
      );
    });

    test("allows one UTxO to be both a spending input and collateral", () async {
      final input = _utxo(hashByte: 18, index: 0, address: _walletAddress, lovelace: 10);
      final tx = _tx(
        inputs: [input.identifier],
        collateral: [input.identifier],
        outputs: [_output(_walletAddress, 8)],
      );

      final bundle = await _prepare(txs: [tx], walletUtxos: [input]);

      expect(bundle.txsData.single.txDiff.usedUtxos, [input]);
      expect(bundle.txsData.single.signingAddressesRequired, {_walletAddress});
    });

    test("rejects duplicate transaction bodies", () async {
      final input = _input(hashByte: 19);
      final tx = _tx(inputs: [input], outputs: [_output(_walletAddress, 1)]);

      await expectLater(
        _prepare(txs: [tx, tx], walletUtxos: const []),
        throwsA(isA<InvalidTransactionBatchException>()),
      );
    });

    test("rejects a forward reference to a later transaction output", () async {
      final tx2 = _tx(inputs: [_input(hashByte: 20)], outputs: [_output(_walletAddress, 2)]);
      final futureOutput = CardanoTransactionInput(
        transactionHash: TransactionHash.fromHex(tx2.body.blake2bHash256Hex()),
        index: 0,
      );
      final tx1 = _tx(inputs: [futureOutput], outputs: [_output(_walletAddress, 1)]);

      await expectLater(
        _prepare(txs: [tx1, tx2], walletUtxos: const []),
        throwsA(isA<InvalidTransactionBatchException>()),
      );
    });

    test("rejects a reference to a regular output of an invalid transaction", () async {
      final invalidTx = _tx(
        inputs: [_input(hashByte: 21)],
        collateral: [_input(hashByte: 22)],
        outputs: [_output(_walletAddress, 2)],
        isValid: false,
      );
      final outputThatWillNotExist = CardanoTransactionInput(
        transactionHash: TransactionHash.fromHex(invalidTx.body.blake2bHash256Hex()),
        index: 0,
      );
      final nextTx = _tx(inputs: [outputThatWillNotExist], outputs: [_output(_walletAddress, 1)]);

      await expectLater(
        _prepare(txs: [invalidTx, nextTx], walletUtxos: const []),
        throwsA(isA<InvalidTransactionBatchException>()),
      );
    });

    test("rejects an address-resolved user UTxO without its full output", () async {
      final missingUserInput = _input(hashByte: 23);
      final tx = _tx(inputs: [missingUserInput], outputs: [_output(_walletAddress, 1)]);

      await expectLater(
        SigningUtils.prepareTxsForSigningWithUtxoOwnership(
          txs: [tx],
          walletUtxos: const [],
          utxoAddresses: {UtxoId.fromInput(missingUserInput): _secondaryWalletAddress},
          additionalUserOwnedAddresses: const {_secondaryWalletAddress},
          walletReceiveAddressBech32: _walletAddress,
          drepCredential: _credential,
          constitutionalCommitteeColdCredential: _credential,
          constitutionalCommitteeHotCredential: _credential,
          networkId: NetworkId.mainnet,
        ),
        throwsA(isA<InvalidTransactionBatchException>()),
      );
    });

    test("tracks chained outputs at an explicitly declared wallet address", () async {
      final input = _utxo(hashByte: 27, index: 0, address: _walletAddress, lovelace: 10);
      final tx1 = _tx(inputs: [input.identifier], outputs: [_output(_secondaryWalletAddress, 8)]);
      final chainedInput = CardanoTransactionInput(
        transactionHash: TransactionHash.fromHex(tx1.body.blake2bHash256Hex()),
        index: 0,
      );
      final tx2 = _tx(inputs: [chainedInput], outputs: [_output(_walletAddress, 1)]);

      final preparation = await SigningUtils.prepareTxsForSigningWithUtxoOwnership(
        txs: [tx1, tx2],
        walletUtxos: [input],
        utxoAddresses: const {},
        additionalUserOwnedAddresses: const {_secondaryWalletAddress},
        walletReceiveAddressBech32: _walletAddress,
        drepCredential: _credential,
        constitutionalCommitteeColdCredential: _credential,
        constitutionalCommitteeHotCredential: _credential,
        networkId: NetworkId.mainnet,
      );

      expect(preparation.signingBundle.txsData[1].txDiff.diff.lovelace, BigInt.from(-7).toCborInt());
      expect(preparation.signingBundle.txsData[1].signingAddressesRequired, {_secondaryWalletAddress});
      expect(preparation.transactions[1].utxoOwnership[UtxoId.fromInput(chainedInput)], isA<UserOwnedUtxo>());
    });

    test("detects wallet deregistrations followed by unrelated certificates", () async {
      final walletStakeCredentialBytes = CardanoAddress.fromBech32OrBase58(_walletAddress).stakeCredentialsBytes;
      if (walletStakeCredentialBytes == null) fail("The wallet test address must contain stake credentials.");
      final walletStakeCredential = Credential(CredType.ADDR_KEY_HASH, walletStakeCredentialBytes);
      final walletDrepCredential = Credential(CredType.ADDR_KEY_HASH, _credential.hexDecode());
      final unrelatedCredential = Credential(CredType.ADDR_KEY_HASH, Uint8List(28)..fillRange(0, 28, 1));
      final input = _utxo(hashByte: 24, index: 0, address: _walletAddress, lovelace: 10);
      final tx = _tx(
        inputs: [input.identifier],
        outputs: [_output(_walletAddress, 8)],
        certs: Certificates(
          certificates: [
            Certificate.stakeDeRegistrationLegacy(stakeCredential: walletStakeCredential),
            Certificate.unregisterDRep(dRepCredential: walletDrepCredential, coin: BigInt.zero.toCborInt()),
            Certificate.registerDRep(
              dRepCredential: unrelatedCredential,
              coin: BigInt.zero.toCborInt(),
              anchor: null,
            ),
          ],
          cborTags: const [],
          lengthType: CborLengthType.definite,
        ),
      );

      final bundle = await _prepare(txs: [tx], walletUtxos: [input]);

      expect(bundle.txsData.single.txDiff.stakeDeregistration, isTrue);
      expect(bundle.txsData.single.txDiff.dRepDeregistration, isTrue);
      expect(bundle.stakeDeregistration, isTrue);
      expect(bundle.dRepDeregistration, isTrue);
    });
  });
}

Future<TxSigningBundle> _prepare({
  required List<CardanoTransaction> txs,
  required List<Utxo> walletUtxos,
}) => SigningUtils.prepareTxsForSigning(
  txs: txs,
  walletUtxos: walletUtxos,
  walletReceiveAddressBech32: _walletAddress,
  drepCredential: _credential,
  constitutionalCommitteeColdCredential: _credential,
  constitutionalCommitteeHotCredential: _credential,
  networkId: NetworkId.mainnet,
);

CardanoTransaction _tx({
  required List<CardanoTransactionInput> inputs,
  required List<CardanoTransactionOutput> outputs,
  List<CardanoTransactionInput> collateral = const [],
  List<CardanoTransactionInput> referenceInputs = const [],
  Certificates? certs,
  CardanoTransactionOutput? collateralReturn,
  bool isValid = true,
}) => cardanoTx(
  body: txBody(
    inputs: CardanoTransactionInputs(data: inputs, cborTags: const []),
    outputs: outputs,
    collateral: collateral.isEmpty ? null : CardanoTransactionInputs(data: collateral, cborTags: const []),
    referenceInputs: referenceInputs.isEmpty
        ? null
        : CardanoTransactionInputs(data: referenceInputs, cborTags: const []),
    certs: certs,
    collateralReturn: collateralReturn,
  ),
  isValidDi: isValid,
);

Utxo _utxo({
  required int hashByte,
  required int index,
  required String address,
  required int lovelace,
}) => Utxo(
  identifier: CardanoTransactionInput(
    transactionHash: TransactionHash(value: Uint8List(32)..fillRange(0, 32, hashByte)),
    index: index,
  ),
  content: _output(address, lovelace),
);

CardanoTransactionInput _input({required int hashByte, int index = 0}) => CardanoTransactionInput(
  transactionHash: TransactionHash(value: Uint8List(32)..fillRange(0, 32, hashByte)),
  index: index,
);

CardanoTransactionOutput _output(String address, int lovelace) => CardanoTransactionOutput.postAlonzo(
  address: Address.fromBase58OrBech32(address),
  value: _lovelace(lovelace),
  outDatum: null,
  scriptRef: null,
  lengthType: CborLengthType.definite,
);

CardanoTransactionOutput _bigOutput(String address, BigInt lovelace) => CardanoTransactionOutput.postAlonzo(
  address: Address.fromBase58OrBech32(address),
  value: Value.v0(lovelace: lovelace.toCborInt()),
  outDatum: null,
  scriptRef: null,
  lengthType: CborLengthType.definite,
);

Value _lovelace(int amount) => Value.v0(lovelace: BigInt.from(amount).toCborInt());

String _utxoKey(CardanoTransactionInput input) => "${input.transactionHash.hexValue}#${input.index}";
