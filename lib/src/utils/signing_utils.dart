import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "../../workers/wallet_tasks.dart";

class SigningUtils {
  const SigningUtils._();

  static Future<TxSigningBundle> prepareTxsForSigning({
    required List<CardanoTransaction> txs,
    required List<Utxo> walletUtxos,
    required String walletReceiveAddressBech32,
    required String drepCredential,
    required String constitutionalCommitteeColdCredential,
    required String constitutionalCommitteeHotCredential,
    required NetworkId networkId,
  }) => cardanoWorker.prepareTxsForSigningImpl(
    walletReceiveAddressBech32,
    drepCredential,
    constitutionalCommitteeColdCredential,
    constitutionalCommitteeHotCredential,
    networkId,
    txs,
    walletUtxos,
  );

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
