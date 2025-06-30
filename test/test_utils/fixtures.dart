import "dart:typed_data";

import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:cardano_flutter_sdk/src/utils/sugar.dart";

const emptyWitnessSet = WitnessSet();

CardanoTransaction cardanoTx({
  required CardanoTransactionBody body,
  WitnessSet? witnessSet,
  bool isValidDi = true,
  CBORMetadata? auxiliaryData,
  bool overrideBodyMetadataHash = false,
}) =>
    CardanoTransaction(
      body: body,
      witnessSet: witnessSet ?? const WitnessSet(),
      isValidDi: isValidDi,
      auxiliaryData: auxiliaryData,
      overrideBodyMetadataHash: overrideBodyMetadataHash,
    );

CardanoTransactionBody txBody({
  CardanoTransactionInputs inputs = const CardanoTransactionInputs(data: [], cborTags: []), // 0
  List<CardanoTransactionOutput> outputs = const [], // 1
  BigInt? fee, // 2
  // OPTIONAL
  BigInt? ttl, // 3
  List<Certificate>? certs, // 4
  List<Withdraw>? withdrawals, // 5
  // 6 - update ; what is it?
  Uint8List? metadataHash, // 7
  BigInt? validityStartInterval, // 8
  List<MultiAsset>? mint, // 9
  Uint8List? scriptDataHash, // 11
  CardanoTransactionInputs? collateral, // 13
  RequiredSigners? requiredSigners, // 14
  NetworkId? networkId, // 15
  // BABBAGE ERA
  CardanoTransactionOutput? collateralReturn, // 16
  BigInt? totalCollateral, // 17
  CardanoTransactionInputs? referenceInputs, // 18
  // CONWAY ERA
  VotingProcedures? votingProcedures, // 19
  List<ProposalProcedure>? proposalProcedures, // 20
  BigInt? currentTreasuryValue, // 21
  BigInt? donation, // 22
}) =>
    CardanoTransactionBody.create(
      inputs: inputs,
      outputs: outputs,
      fee: fee ?? BigInt.zero,
      ttl: ttl,
      certs: certs,
      withdrawals: withdrawals,
      metadataHash: metadataHash,
      validityStartInterval: validityStartInterval,
      mint: mint,
      scriptDataHash: scriptDataHash,
      collateral: collateral,
      requiredSigners: requiredSigners,
      networkId: networkId,
      collateralReturn: collateralReturn,
      totalCollateral: totalCollateral,
      referenceInputs: referenceInputs,
      votingProcedures: votingProcedures,
      proposalProcedures: proposalProcedures,
    );

WitnessSet witnessSet({
  List<WitnessVKey>? vkeyWitnesses,
  List<NativeScript>? nativeScripts,
  List<WitnessBootstrap>? bootstrap,
  List<PlutusScriptV1>? plutusScriptV1,
  List<PlutusData>? plutusData,
  List<Redeemer>? redeemer,
  List<PlutusScriptV2>? plutusScriptV2,
}) =>
    WitnessSet(
      ivkeyWitnesses: vkeyWitnesses?.let((p0) => ListWithCborType(p0, CborLengthType.auto, null)),
      ibootstrap: bootstrap?.let((p0) => ListWithCborType(p0, CborLengthType.auto, null)),
      inativeScripts: nativeScripts?.let((p0) => ListWithCborType(p0, CborLengthType.auto, null)),
      iplutusScriptV1: plutusScriptV1?.let((p0) => ListWithCborType(p0, CborLengthType.auto, null)),
      iplutusData: plutusData?.let((p0) => ListWithCborType(p0, CborLengthType.auto, null)),
      iredeemer: redeemer?.let((p0) => ListWithCborType(p0, CborLengthType.auto, null)),
      iplutusScriptV2: plutusScriptV2?.let((p0) => ListWithCborType(p0, CborLengthType.auto, null)),
    );
