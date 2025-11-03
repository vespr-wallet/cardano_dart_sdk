import "package:bip32_ed25519/api.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:squadron/squadron.dart";

import "../cardano_flutter_sdk.dart";

const kIsWeb = true;

const cardanoSignerMarshaler = _CardanoSignerMarshaler();
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

abstract class UInt8ListMarshaler<T> implements GenericMarshaler<T> {
  const UInt8ListMarshaler();

  @override
  dynamic marshal(T data, [MarshalingContext? context]) => marshalToBytes(data);

  @override
  T unmarshal(dynamic data, [MarshalingContext? context]) => unmarshalFromBytes(data as Uint8List);

  Uint8List marshalToBytes(T data);

  T unmarshalFromBytes(Uint8List data);
}

class _CardanoSignerMarshaler extends UInt8ListMarshaler<CardanoSigner> {
  const _CardanoSignerMarshaler();

  @override
  Uint8List marshalToBytes(CardanoSigner data) => data.marshal();

  @override
  CardanoSigner unmarshalFromBytes(Uint8List data) => CardanoSigner.unmarshal(data);
}

class _DataSignatureMarshaler extends UInt8ListMarshaler<DataSignature> {
  const _DataSignatureMarshaler();

  @override
  Uint8List marshalToBytes(DataSignature data) => data.marshal();

  @override
  DataSignature unmarshalFromBytes(Uint8List data) => DataSignature.unmarshal(data);
}

class _UtxoListMarshaler extends UInt8ListMarshaler<List<Utxo>> {
  const _UtxoListMarshaler();

  @override
  Uint8List marshalToBytes(List<Utxo> data) {
    final writer = BinaryWriterImpl();
    writer.writeBytesList(
      data.map((e) => e.serializeAsBytes()).toList(),
    );

    return writer.toBytes();
  }

  @override
  List<Utxo> unmarshalFromBytes(Uint8List data) {
    return BinaryReaderImpl(data)
        .readBytesList() //
        .map(Utxo.deserializeBytes)
        .toList();
  }
}

class _CardanoTransactionListMarshaler extends UInt8ListMarshaler<List<CardanoTransaction>> {
  const _CardanoTransactionListMarshaler();

  @override
  Uint8List marshalToBytes(List<CardanoTransaction> data) {
    final writer = BinaryWriterImpl();
    writer.writeBytesList(
      data.map((e) => e.serializeAsBytes()).toList(),
    );

    return writer.toBytes();
  }

  @override
  List<CardanoTransaction> unmarshalFromBytes(Uint8List data) {
    return BinaryReaderImpl(data)
        .readBytesList() //
        .map(CardanoTransaction.deserializeBytes)
        .toList();
  }
}

class _CredentialTypeMarshaler extends UInt8ListMarshaler<CredentialType> {
  const _CredentialTypeMarshaler();

  @override
  Uint8List marshalToBytes(CredentialType data) => data.index.toBytes();

  @override
  CredentialType unmarshalFromBytes(Uint8List data) => CredentialType.values[data.toInt32()];
}

class _CardanoAddressMarshaler extends UInt8ListMarshaler<CardanoAddress> {
  const _CardanoAddressMarshaler();

  @override
  Uint8List marshalToBytes(CardanoAddress data) => data.marshal().utf8Decode();

  @override
  CardanoAddress unmarshalFromBytes(Uint8List data) => CardanoAddress.unmarshal(data.utf8Encode());
}

class _Bip32PublicKeyKeyMarshaler extends UInt8ListMarshaler<Bip32PublicKey> {
  const _Bip32PublicKeyKeyMarshaler();

  @override
  Uint8List marshalToBytes(Bip32PublicKey data) => Uint8List.fromList(data);

  @override
  Bip32PublicKey unmarshalFromBytes(Uint8List data) => Bip32VerifyKey(data);
}

class _Bip32PublicKeysKeyMarshaler extends UInt8ListMarshaler<List<Bip32PublicKey>> {
  const _Bip32PublicKeysKeyMarshaler();

  @override
  Uint8List marshalToBytes(List<Bip32PublicKey> data) =>
      (BinaryWriterImpl() //
            ..writeBytesList(data.map(Uint8List.fromList).toList())) //
          .toBytes();

  @override
  List<Bip32PublicKey> unmarshalFromBytes(Uint8List data) =>
      BinaryReaderImpl(data).readBytesList().map(Bip32VerifyKey.new).toList();
}

class _WalletMarshaler extends UInt8ListMarshaler<CardanoWalletImpl> {
  const _WalletMarshaler();

  @override
  Uint8List marshalToBytes(CardanoWallet data) => data.marshal();

  @override
  CardanoWalletImpl unmarshalFromBytes(Uint8List data) => CardanoWalletImpl.unmarshal(data);
}

class _TxSigningBundleMarshaler extends UInt8ListMarshaler<TxSigningBundle> {
  const _TxSigningBundleMarshaler();

  @override
  Uint8List marshalToBytes(TxSigningBundle data) => data.marshal();

  @override
  TxSigningBundle unmarshalFromBytes(Uint8List data) => TxSigningBundle.unmarshal(data);
}

class _TxSignedBundleMarshaler extends UInt8ListMarshaler<TxSignedBundle> {
  const _TxSignedBundleMarshaler();

  @override
  Uint8List marshalToBytes(TxSignedBundle data) => data.marshal();

  @override
  TxSignedBundle unmarshalFromBytes(Uint8List data) => TxSignedBundle.unmarshal(data);
}

class _NetworkIdMarshaler extends UInt8ListMarshaler<NetworkId> {
  const _NetworkIdMarshaler();

  @override
  Uint8List marshalToBytes(NetworkId data) => data.intValue.toBytes();

  @override
  NetworkId unmarshalFromBytes(Uint8List data) => NetworkId.fromIntValue(data.toInt32());
}

class _HdWalletMarshaler extends UInt8ListMarshaler<HdWallet> {
  const _HdWalletMarshaler();

  @override
  Uint8List marshalToBytes(HdWallet data) => data.marshal();

  @override
  HdWallet unmarshalFromBytes(Uint8List data) => HdWallet.unmarshal(data);
}

class _Bip32KeyRoleMarshaler extends UInt8ListMarshaler<Bip32KeyRole> {
  const _Bip32KeyRoleMarshaler();

  @override
  Uint8List marshalToBytes(Bip32KeyRole data) => data.derivationIndex.toBytes();

  @override
  Bip32KeyRole unmarshalFromBytes(Uint8List data) => Bip32KeyRole.fromDerivationIndex(data.toInt32());
}

class _CardanoAddressKitMarshaler extends UInt8ListMarshaler<CardanoAddressKit> {
  const _CardanoAddressKitMarshaler();

  @override
  Uint8List marshalToBytes(CardanoAddressKit data) => data.marshal();

  @override
  CardanoAddressKit unmarshalFromBytes(Uint8List data) => CardanoAddressKit.unmarshal(data);
}

class _StringListMarshaler extends UInt8ListMarshaler<List<String>> {
  const _StringListMarshaler();

  @override
  Uint8List marshalToBytes(List<String> data) {
    final writer = BinaryWriterImpl();
    writer.writeStringList(data);

    return writer.toBytes();
  }

  @override
  List<String> unmarshalFromBytes(Uint8List data) {
    final reader = BinaryReaderImpl(data);
    return reader.readStringList();
  }
}

// Lightweight marshaling extensions to avoid BinaryWriterImpl overhead
extension on int {
  Uint8List toBytes() {
    final bytes = Uint8List(4);
    ByteData.view(bytes.buffer).setUint32(0, this, Endian.little);
    return bytes;
  }
}

extension on Uint8List {
  int toInt32() => ByteData.view(buffer).getUint32(0, Endian.little);
}
