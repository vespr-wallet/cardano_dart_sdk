import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/workers/marshaler.vm.dart"
    if (dart.library.js_interop) "package:cardano_flutter_sdk/workers/marshaler.web.dart";
import "package:cardano_flutter_sdk/workers/wallet_tasks.dart";
import "package:test/test.dart";

import "test_utils/fixtures.dart";

const _walletAddress =
    "addr1q8jn5f9jl0hw7w7r4hz4vgsf9nyvzuh66cwzx8gntrjlqge8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6q5qswjx";
const _secondaryWalletAddress =
    "addr1qyfs44hfdvrwxk30x0u28t8mezf4620jkecfkeqh4j2gusf8959c07mmj4saf577u34c6s32328v24w9zn3tzhc89y6qxz45yy";
const _credential = "00000000000000000000000000000000000000000000000000000000";

void main() {
  group("prepareTxsForSigning cross-platform implementation", () {
    test("uses canonical UTxO ids and tracks all wallet addresses", () async {
      final input = _utxo(hashByte: 1, address: _walletAddress, lovelace: BigInt.from(10));
      final inputWithCborTag = CardanoTransactionInput(
        transactionHash: TransactionHash(value: input.identifier.transactionHash.value, cborTags: const [42]),
        index: 0,
      );
      final tx1 = _tx(inputs: [inputWithCborTag], outputs: [_output(_secondaryWalletAddress, BigInt.from(8))]);
      final chainedInput = CardanoTransactionInput(
        transactionHash: TransactionHash.fromHex(tx1.body.blake2bHash256Hex()),
        index: 0,
      );
      final tx2 = _tx(inputs: [chainedInput], outputs: [_output(_walletAddress, BigInt.one)]);

      final bundle = await _prepareDirect(txs: [tx1, tx2], walletUtxos: [input]);
      final roundTrippedBundle = txSigningBundleMarshaler.unmarshal(txSigningBundleMarshaler.marshal(bundle));

      expect(roundTrippedBundle.totalDiff.lovelace, BigInt.from(-9).toCborInt());
      expect(roundTrippedBundle.txsData[0].signingAddressesRequired, {_walletAddress});
      expect(roundTrippedBundle.txsData[1].signingAddressesRequired, {_secondaryWalletAddress});
    });

    test("preserves invalid collateral amounts beyond 53 bits", () async {
      final collateralAmount = BigInt.parse("31718971375682855");
      final returnAmount = BigInt.parse("10000000000000000");
      final normalInput = _utxo(hashByte: 2, address: _walletAddress, lovelace: BigInt.from(10));
      final collateralInput = _utxo(hashByte: 3, address: _walletAddress, lovelace: collateralAmount);
      final tx = _tx(
        inputs: [normalInput.identifier],
        collateral: [collateralInput.identifier],
        outputs: [_output(_walletAddress, BigInt.from(7))],
        collateralReturn: _output(_walletAddress, returnAmount),
        isValid: false,
      );

      final bundle = await _prepareDirect(txs: [tx], walletUtxos: [normalInput, collateralInput]);
      final roundTrippedBundle = txSigningBundleMarshaler.unmarshal(txSigningBundleMarshaler.marshal(bundle));

      expect(roundTrippedBundle.totalDiff.lovelace, (returnAmount - collateralAmount).toCborInt());
      expect(roundTrippedBundle.txsData.single.txDiff.usedUtxos, [collateralInput]);
    });

    test("keeps deregistration flags when unrelated certificates follow", () async {
      final walletStakeCredentialBytes = CardanoAddress.fromBech32OrBase58(_walletAddress).stakeCredentialsBytes;
      if (walletStakeCredentialBytes == null) fail("The wallet test address must contain stake credentials.");
      final input = _utxo(hashByte: 4, address: _walletAddress, lovelace: BigInt.from(10));
      final tx = _tx(
        inputs: [input.identifier],
        outputs: [_output(_walletAddress, BigInt.from(8))],
        certs: Certificates(
          certificates: [
            Certificate.stakeDeRegistrationLegacy(
              stakeCredential: Credential(CredType.ADDR_KEY_HASH, walletStakeCredentialBytes),
            ),
            Certificate.unregisterDRep(
              dRepCredential: Credential(CredType.ADDR_KEY_HASH, _credential.hexDecode()),
              coin: BigInt.zero.toCborInt(),
            ),
            Certificate.registerDRep(
              dRepCredential: Credential(CredType.ADDR_KEY_HASH, Uint8List(28)..fillRange(0, 28, 1)),
              coin: BigInt.zero.toCborInt(),
              anchor: null,
            ),
          ],
          cborTags: const [],
          lengthType: CborLengthType.definite,
        ),
      );

      final bundle = await _prepareDirect(txs: [tx], walletUtxos: [input]);

      expect(bundle.stakeDeregistration, isTrue);
      expect(bundle.dRepDeregistration, isTrue);
    });
  });
}

Future<TxSigningBundle> _prepareDirect({
  required List<CardanoTransaction> txs,
  required List<Utxo> walletUtxos,
}) => WalletTasks().prepareTxsForSigningImpl(
  _walletAddress,
  _credential,
  _credential,
  _credential,
  NetworkId.mainnet,
  txs,
  walletUtxos,
  const [_walletAddress, _secondaryWalletAddress],
);

CardanoTransaction _tx({
  required List<CardanoTransactionInput> inputs,
  required List<CardanoTransactionOutput> outputs,
  List<CardanoTransactionInput> collateral = const [],
  Certificates? certs,
  CardanoTransactionOutput? collateralReturn,
  bool isValid = true,
}) => cardanoTx(
  body: txBody(
    inputs: CardanoTransactionInputs(data: inputs, cborTags: const []),
    outputs: outputs,
    collateral: collateral.isEmpty ? null : CardanoTransactionInputs(data: collateral, cborTags: const []),
    certs: certs,
    collateralReturn: collateralReturn,
  ),
  isValidDi: isValid,
);

Utxo _utxo({required int hashByte, required String address, required BigInt lovelace}) => Utxo(
  identifier: CardanoTransactionInput(
    transactionHash: TransactionHash(value: Uint8List(32)..fillRange(0, 32, hashByte)),
    index: 0,
  ),
  content: _output(address, lovelace),
);

CardanoTransactionOutput _output(String address, BigInt lovelace) => CardanoTransactionOutput.postAlonzo(
  address: Address.fromBase58OrBech32(address),
  value: Value.v0(lovelace: lovelace.toCborInt()),
  outDatum: null,
  scriptRef: null,
  lengthType: CborLengthType.definite,
);
