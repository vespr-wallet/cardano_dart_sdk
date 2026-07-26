import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:meta/meta.dart";

const unresolvedUtxosTransparencyWarning = "This transaction is not fully transparent due to unresolved UTxO(s).";

/// A canonical Cardano UTxO reference that ignores CBOR encoding metadata.
@immutable
final class UtxoId {
  factory UtxoId({required String transactionHash, required int index}) {
    if (index < 0) throw ArgumentError.value(index, "index", "A UTxO index cannot be negative.");
    final hash = TransactionHash.fromHex(transactionHash);
    if (hash.value.length != 32) {
      throw ArgumentError.value(transactionHash, "transactionHash", "A transaction hash must contain 32 bytes.");
    }
    return UtxoId._(transactionHash: hash.hexValue, index: index);
  }

  const UtxoId._({required this.transactionHash, required this.index});

  factory UtxoId.fromInput(CardanoTransactionInput input) {
    if (input.index < 0) throw ArgumentError.value(input.index, "input.index", "A UTxO index cannot be negative.");
    if (input.transactionHash.value.length != 32) {
      throw ArgumentError.value(
        input.transactionHash.hexValue,
        "input.transactionHash",
        "A transaction hash must contain 32 bytes.",
      );
    }
    return UtxoId._(transactionHash: input.transactionHash.hexValue, index: input.index);
  }

  final String transactionHash;
  final int index;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UtxoId && transactionHash == other.transactionHash && index == other.index;

  @override
  int get hashCode => Object.hash(transactionHash, index);

  @override
  String toString() => "$transactionHash#$index";
}

/// Whether a transaction UTxO is controlled by the user, another party, or cannot be resolved.
sealed class UtxoOwnership {
  const UtxoOwnership();

  String? get address;
}

/// A UTxO at an address declared as controlled by this wallet.
final class UserOwnedUtxo extends UtxoOwnership {
  const UserOwnedUtxo({required this.address});

  @override
  final String address;
}

/// A UTxO with a resolved address that is not controlled by this wallet.
final class ExternalUtxo extends UtxoOwnership {
  const ExternalUtxo({required this.address});

  @override
  final String address;
}

/// A UTxO for which no address resolution was supplied.
final class UnresolvedUtxo extends UtxoOwnership {
  const UnresolvedUtxo();

  @override
  String? get address => null;
}

/// Ownership transparency for every spending, collateral, and reference input in one transaction.
final class TxUtxoTransparency {
  TxUtxoTransparency({
    required this.transactionIndex,
    required this.transactionId,
    required Map<UtxoId, UtxoOwnership> utxoOwnership,
  }) : utxoOwnership = Map.unmodifiable(utxoOwnership);

  final int transactionIndex;
  final String transactionId;
  final Map<UtxoId, UtxoOwnership> utxoOwnership;

  Set<UtxoId> get unresolvedUtxos => {
    for (final entry in utxoOwnership.entries)
      if (entry.value is UnresolvedUtxo) entry.key,
  };

  bool get isFullyTransparent => unresolvedUtxos.isEmpty;

  String? get transparencyWarning => isFullyTransparent ? null : unresolvedUtxosTransparencyWarning;
}

/// A signing bundle together with the ownership information needed to assess its transparency.
final class TxSigningPreparation {
  TxSigningPreparation({
    required this.signingBundle,
    required List<TxUtxoTransparency> transactions,
  }) : transactions = List.unmodifiable(transactions);

  final TxSigningBundle signingBundle;
  final List<TxUtxoTransparency> transactions;

  bool get isFullyTransparent => transactions.every((transaction) => transaction.isFullyTransparent);
}

/// The supplied transaction sequence cannot represent a valid, ordered Cardano batch.
final class InvalidTransactionBatchException implements Exception {
  const InvalidTransactionBatchException(this.message);

  final String message;

  @override
  String toString() => "InvalidTransactionBatchException: $message";
}
