import "package:bip32_ed25519/api.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:squadron/squadron.dart";

import "../cardano_flutter_sdk.dart";

const kIsWeb = false;

class IdentityMarshaler<T> implements SquadronMarshaler<T, T> {
  const IdentityMarshaler();

  @override
  T marshal(T data) => data;

  @override
  T unmarshal(T data) => data;
}

class DataSignatureMarshaler extends IdentityMarshaler<DataSignature> {
  const DataSignatureMarshaler();
}

class UtxoListMarshaler extends IdentityMarshaler<List<Utxo>> {
  const UtxoListMarshaler();
}

class CardanoTransactionListMarshaler extends IdentityMarshaler<List<CardanoTransaction>> {
  const CardanoTransactionListMarshaler();
}

class CredentialTypeMarshaler extends IdentityMarshaler<CredentialType> {
  const CredentialTypeMarshaler();
}

class CardanoAddressMarshaler extends IdentityMarshaler<CardanoAddress> {
  const CardanoAddressMarshaler();
}

class Bip32PublicKeyKeyMarshaler extends IdentityMarshaler<Bip32PublicKey> {
  const Bip32PublicKeyKeyMarshaler();
}

class Bip32PublicKeysKeyMarshaler extends IdentityMarshaler<List<Bip32PublicKey>> {
  const Bip32PublicKeysKeyMarshaler();
}

class WalletMarshaler extends IdentityMarshaler<CardanoWallet> {
  const WalletMarshaler();
}

class TxSigningBundleMarshaler extends IdentityMarshaler<TxSigningBundle> {
  const TxSigningBundleMarshaler();
}

class TxSignedBundleMarshaler extends IdentityMarshaler<TxSignedBundle> {
  const TxSignedBundleMarshaler();
}

class NetworkIdMarshaler extends IdentityMarshaler<NetworkId> {
  const NetworkIdMarshaler();
}

class CardanoAddressKitMarshaler extends IdentityMarshaler<CardanoAddressKit> {
  const CardanoAddressKitMarshaler();
}

class HdWalletMarshaler extends IdentityMarshaler<HdWallet> {
  const HdWalletMarshaler();
}

class Bip32KeyRoleMarshaler extends IdentityMarshaler<Bip32KeyRole> {
  const Bip32KeyRoleMarshaler();
}

class StringListMarshaler extends IdentityMarshaler<List<String>> {
  const StringListMarshaler();
}
