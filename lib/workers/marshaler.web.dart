import "package:bip32_ed25519/api.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:squadron/squadron.dart";

import "../cardano_flutter_sdk.dart";

const kIsWeb = true;

const dataSignatureMarshaler = _DataSignatureMarshaler();
const utxoListMarshaler = _UtxoListMarshaler();
const cardanoTransactionListMarshaler = _CardanoTransactionListMarshaler();
const credentialTypeMarshaler = _CredentialTypeMarshaler();
const cardanoAddressMarshaler = _CardanoAddressMarshaler();
const bip32PublicKeyKeyMarshaler = _Bip32PublicKeyKeyMarshaler();
const bip32PublicKeysKeyMarshaler = _Bip32PublicKeysKeyMarshaler();
const walletMarshaler = _WalletMarshaler();
const txSigningBundleMarshaler = _TxSigningBundleMarshaler();
const txSignedBundleMarshaler = _TxSignedBundleMarshaler();
const networkIdMarshaler = _NetworkIdMarshaler();
const cardanoAddressKitMarshaler = _CardanoAddressKitMarshaler();
const hdWalletMarshaler = _HdWalletMarshaler();
const bip32KeyRoleMarshaler = _Bip32KeyRoleMarshaler();
const stringListMarshaler = _StringListMarshaler();

class _DataSignatureMarshaler implements GenericMarshaler<DataSignature> {
  const _DataSignatureMarshaler();

  @override
  dynamic marshal(DataSignature data, [MarshalingContext? context]) => data.marshal();

  @override
  DataSignature unmarshal(dynamic data, [MarshalingContext? context]) => DataSignature.unmarshal(data as Uint8List);
}

class _UtxoListMarshaler implements GenericMarshaler<List<Utxo>> {
  const _UtxoListMarshaler();

  @override
  dynamic marshal(List<Utxo> data, [MarshalingContext? context]) {
    final writer = BinaryWriterImpl();
    writer.writeBytesList(
      data.map((e) => e.serializeAsBytes()).toList(),
    );

    return writer.toBytes();
  }

  @override
  List<Utxo> unmarshal(dynamic data, [MarshalingContext? context]) {
    return BinaryReaderImpl(data)
        .readBytesList() //
        .map(Utxo.deserializeBytes)
        .toList();
  }
}

class _CardanoTransactionListMarshaler implements GenericMarshaler<List<CardanoTransaction>> {
  const _CardanoTransactionListMarshaler();

  @override
  dynamic marshal(List<CardanoTransaction> data, [MarshalingContext? context]) {
    final writer = BinaryWriterImpl();
    writer.writeBytesList(
      data.map((e) => e.serializeAsBytes()).toList(),
    );

    return writer.toBytes();
  }

  @override
  List<CardanoTransaction> unmarshal(dynamic data, [MarshalingContext? context]) {
    return BinaryReaderImpl(data)
        .readBytesList() //
        .map(CardanoTransaction.deserializeBytes)
        .toList();
  }
}

class _CredentialTypeMarshaler implements GenericMarshaler<CredentialType> {
  const _CredentialTypeMarshaler();

  @override
  int marshal(CredentialType data, [MarshalingContext? context]) => data.index;

  @override
  CredentialType unmarshal(dynamic data, [MarshalingContext? context]) => CredentialType.values[data as int];
}

class _CardanoAddressMarshaler implements GenericMarshaler<CardanoAddress> {
  const _CardanoAddressMarshaler();

  @override
  String marshal(CardanoAddress data, [MarshalingContext? context]) => data.marshal();

  @override
  CardanoAddress unmarshal(dynamic data, [MarshalingContext? context]) => CardanoAddress.unmarshal(data as String);
}

class _Bip32PublicKeyKeyMarshaler implements GenericMarshaler<Bip32PublicKey> {
  const _Bip32PublicKeyKeyMarshaler();

  @override
  dynamic marshal(Bip32PublicKey data, [MarshalingContext? context]) => Uint8List.fromList(data);

  @override
  Bip32PublicKey unmarshal(dynamic data, [MarshalingContext? context]) => Bip32VerifyKey(data as Uint8List);
}

class _Bip32PublicKeysKeyMarshaler implements GenericMarshaler<List<Bip32PublicKey>> {
  const _Bip32PublicKeysKeyMarshaler();

  @override
  dynamic marshal(List<Bip32PublicKey> data, [MarshalingContext? context]) => (BinaryWriterImpl() //
        ..writeBytesList(data.map(Uint8List.fromList).toList())) //
      .toBytes();

  @override
  List<Bip32PublicKey> unmarshal(dynamic data, [MarshalingContext? context]) =>
      BinaryReaderImpl(data as Uint8List).readBytesList().map(Bip32VerifyKey.new).toList();
}

class _WalletMarshaler implements GenericMarshaler<CardanoWallet> {
  const _WalletMarshaler();

  @override
  dynamic marshal(CardanoWallet data, [MarshalingContext? context]) => data.marshal();

  @override
  CardanoWallet unmarshal(dynamic data, [MarshalingContext? context]) => CardanoWalletImpl.unmarshal(data as Uint8List);
}

class _TxSigningBundleMarshaler implements GenericMarshaler<TxSigningBundle> {
  const _TxSigningBundleMarshaler();

  @override
  dynamic marshal(TxSigningBundle data, [MarshalingContext? context]) => data.marshal();

  @override
  TxSigningBundle unmarshal(dynamic data, [MarshalingContext? context]) => TxSigningBundle.unmarshal(data as Uint8List);
}

class _TxSignedBundleMarshaler implements GenericMarshaler<TxSignedBundle> {
  const _TxSignedBundleMarshaler();

  @override
  dynamic marshal(TxSignedBundle data, [MarshalingContext? context]) => data.marshal();

  @override
  TxSignedBundle unmarshal(dynamic data, [MarshalingContext? context]) => TxSignedBundle.unmarshal(data as Uint8List);
}

class _NetworkIdMarshaler implements GenericMarshaler<NetworkId> {
  const _NetworkIdMarshaler();

  @override
  int marshal(NetworkId data, [MarshalingContext? context]) => data.intValue;

  @override
  NetworkId unmarshal(dynamic data, [MarshalingContext? context]) => NetworkId.fromIntValue(data as int);
}

class _HdWalletMarshaler implements GenericMarshaler<HdWallet> {
  const _HdWalletMarshaler();

  @override
  dynamic marshal(HdWallet data, [MarshalingContext? context]) => data.marshal();

  @override
  HdWallet unmarshal(dynamic data, [MarshalingContext? context]) => HdWallet.unmarshal(data as Uint8List);
}

class _Bip32KeyRoleMarshaler implements SquadronMarshaler<Bip32KeyRole, int> {
  const _Bip32KeyRoleMarshaler();

  @override
  int marshal(Bip32KeyRole data, [MarshalingContext? context]) => data.derivationIndex;

  @override
  Bip32KeyRole unmarshal(dynamic data, [MarshalingContext? context]) => Bip32KeyRole.fromDerivationIndex(data as int);
}

class _CardanoAddressKitMarshaler implements GenericMarshaler<CardanoAddressKit> {
  const _CardanoAddressKitMarshaler();

  @override
  dynamic marshal(CardanoAddressKit data, [MarshalingContext? context]) => data.marshal();

  @override
  CardanoAddressKit unmarshal(dynamic data, [MarshalingContext? context]) =>
      CardanoAddressKit.unmarshal(data as Uint8List);
}

class _StringListMarshaler implements GenericMarshaler<List<String>> {
  const _StringListMarshaler();

  @override
  dynamic marshal(List<String> data, [MarshalingContext? context]) {
    final writer = BinaryWriterImpl();
    writer.writeStringList(data);

    return writer.toBytes();
  }

  @override
  List<String> unmarshal(dynamic data, [MarshalingContext? context]) {
    final reader = BinaryReaderImpl(data as Uint8List);
    return reader.readStringList();
  }
}
