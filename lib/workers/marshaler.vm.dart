import "package:bip32_ed25519/api.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:squadron/squadron.dart";

import "../cardano_flutter_sdk.dart";

const kIsWeb = false;

class GenericIdentityMarshaler<T> implements GenericMarshaler<T> {
  const GenericIdentityMarshaler();

  @override
  T marshal(T data, [MarshalingContext? context]) => data;

  @override
  T unmarshal(dynamic data, [MarshalingContext? context]) => data as T;
}

const dataSignatureMarshaler = GenericIdentityMarshaler<DataSignature>();
const utxoListMarshaler = GenericIdentityMarshaler<List<Utxo>>();
const cardanoTransactionListMarshaler = GenericIdentityMarshaler<List<CardanoTransaction>>();
const credentialTypeMarshaler = GenericIdentityMarshaler<CredentialType>();
const cardanoAddressMarshaler = GenericIdentityMarshaler<CardanoAddress>();
const bip32PublicKeyKeyMarshaler = GenericIdentityMarshaler<Bip32PublicKey>();
const bip32PublicKeysKeyMarshaler = GenericIdentityMarshaler<List<Bip32PublicKey>>();
const walletMarshaler = GenericIdentityMarshaler<CardanoWallet>();
const txSigningBundleMarshaler = GenericIdentityMarshaler<TxSigningBundle>();
const txSignedBundleMarshaler = GenericIdentityMarshaler<TxSignedBundle>();
const networkIdMarshaler = GenericIdentityMarshaler<NetworkId>();
const cardanoAddressKitMarshaler = GenericIdentityMarshaler<CardanoAddressKit>();
const hdWalletMarshaler = GenericIdentityMarshaler<HdWallet>();
const bip32KeyRoleMarshaler = GenericIdentityMarshaler<Bip32KeyRole>();
const stringListMarshaler = GenericIdentityMarshaler<List<String>>();
