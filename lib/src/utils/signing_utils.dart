import "package:cardano_dart_types/cardano_dart_types.dart";
import "../../workers/wallet_tasks.dart";

Future<TxSigningBundle> prepareTxsForSigning({
  required List<CardanoTransaction> txs,
  required List<Utxo> walletUtxos,
  required String walletReceiveAddressBech32,
  required String drepCredential,
  required String constitutionalCommitteeColdCredential,
  required String constitutionalCommitteeHotCredential,
  required NetworkId networkId,
}) =>
    cardanoWorker.prepareTxsForSigningImpl(
      walletReceiveAddressBech32,
      drepCredential,
      constitutionalCommitteeColdCredential,
      constitutionalCommitteeHotCredential,
      networkId,
      txs,
      walletUtxos,
    );
