import "package:bip32_ed25519/api.dart";
import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:squadron/squadron.dart";

import "../cardano_flutter_sdk.dart";

const kIsWeb = true;

class DataSignatureMarshaler implements SquadronMarshaler<DataSignature, Uint8List> {
  const DataSignatureMarshaler();

  @override
  Uint8List marshal(DataSignature data) => data.marshal();

  @override
  DataSignature unmarshal(Uint8List data) => DataSignature.unmarshal(data);
}

class UtxoListMarshaler implements SquadronMarshaler<List<Utxo>, Uint8List> {
  const UtxoListMarshaler();

  @override
  Uint8List marshal(List<Utxo> data) {
    final writer = BinaryWriterImpl();
    writer.writeBytesList(
      data.map((e) => e.serializeAsBytes()).toList(),
    );

    return writer.toBytes();
  }

  @override
  List<Utxo> unmarshal(Uint8List data) {
    return BinaryReaderImpl(data)
        .readBytesList() //
        .map(Utxo.deserializeBytes)
        .toList();
  }
}

class CardanoTransactionListMarshaler implements SquadronMarshaler<List<CardanoTransaction>, Uint8List> {
  const CardanoTransactionListMarshaler();

  @override
  Uint8List marshal(List<CardanoTransaction> data) {
    final writer = BinaryWriterImpl();
    writer.writeBytesList(
      data.map((e) => e.serializeAsBytes()).toList(),
    );

    return writer.toBytes();
  }

  @override
  List<CardanoTransaction> unmarshal(Uint8List data) {
    return BinaryReaderImpl(data)
        .readBytesList() //
        .map(CardanoTransaction.deserializeBytes)
        .toList();
  }
}

class CredentialTypeMarshaler implements SquadronMarshaler<CredentialType, int> {
  const CredentialTypeMarshaler();

  @override
  int marshal(CredentialType data) => data.index;

  @override
  CredentialType unmarshal(int data) => CredentialType.values[data];
}

class CardanoAddressMarshaler implements SquadronMarshaler<CardanoAddress, String> {
  const CardanoAddressMarshaler();

  @override
  String marshal(CardanoAddress data) => data.marshal();

  @override
  CardanoAddress unmarshal(String data) => CardanoAddress.unmarshal(data);
}

class Bip32PublicKeyKeyMarshaler implements SquadronMarshaler<Bip32PublicKey, Uint8List> {
  const Bip32PublicKeyKeyMarshaler();

  @override
  Uint8List marshal(Bip32PublicKey data) => Uint8List.fromList(data);

  @override
  Bip32PublicKey unmarshal(Uint8List data) => Bip32VerifyKey(data);
}

class Bip32PublicKeysKeyMarshaler implements SquadronMarshaler<List<Bip32PublicKey>, Uint8List> {
  const Bip32PublicKeysKeyMarshaler();

  @override
  Uint8List marshal(List<Bip32PublicKey> data) => (BinaryWriterImpl() //
        ..writeBytesList(data.map(Uint8List.fromList).toList())) //
      .toBytes();

  @override
  List<Bip32PublicKey> unmarshal(Uint8List data) =>
      BinaryReaderImpl(data).readBytesList().map(Bip32VerifyKey.new).toList();
}

class WalletMarshaler implements SquadronMarshaler<CardanoWallet, Uint8List> {
  const WalletMarshaler();

  @override
  Uint8List marshal(CardanoWallet data) => data.marshal();

  @override
  CardanoWallet unmarshal(Uint8List data) => CardanoWalletImpl.unmarshal(data);
}

class TxSigningBundleMarshaler implements SquadronMarshaler<TxSigningBundle, Uint8List> {
  const TxSigningBundleMarshaler();

  @override
  Uint8List marshal(TxSigningBundle data) => data.marshal();

  @override
  TxSigningBundle unmarshal(Uint8List data) => TxSigningBundle.unmarshal(data);
}

class TxSignedBundleMarshaler implements SquadronMarshaler<TxSignedBundle, Uint8List> {
  const TxSignedBundleMarshaler();

  @override
  Uint8List marshal(TxSignedBundle data) => data.marshal();

  @override
  TxSignedBundle unmarshal(Uint8List data) => TxSignedBundle.unmarshal(data);
}

class NetworkIdMarshaler implements SquadronMarshaler<NetworkId, int> {
  const NetworkIdMarshaler();

  @override
  int marshal(NetworkId data) => data.intValue;

  @override
  NetworkId unmarshal(int data) => NetworkId.fromIntValue(data);
}

class HdWalletMarshaler implements SquadronMarshaler<HdWallet, Uint8List> {
  const HdWalletMarshaler();

  @override
  Uint8List marshal(HdWallet data) => data.marshal();

  @override
  HdWallet unmarshal(Uint8List data) => HdWallet.unmarshal(data);
}

class Bip32KeyRoleMarshaler implements SquadronMarshaler<Bip32KeyRole, int> {
  const Bip32KeyRoleMarshaler();

  @override
  int marshal(Bip32KeyRole data) => data.derivationIndex;

  @override
  Bip32KeyRole unmarshal(int data) => Bip32KeyRole.fromDerivationIndex(data);
}

class CardanoAddressKitMarshaler implements SquadronMarshaler<CardanoAddressKit, Uint8List> {
  const CardanoAddressKitMarshaler();

  @override
  Uint8List marshal(CardanoAddressKit data) => data.marshal();

  @override
  CardanoAddressKit unmarshal(Uint8List data) => CardanoAddressKit.unmarshal(data);
}

class StringListMarshaler implements SquadronMarshaler<List<String>, Uint8List> {
  const StringListMarshaler();

  @override
  Uint8List marshal(List<String> data) {
    final writer = BinaryWriterImpl();
    writer.writeStringList(data);

    return writer.toBytes();
  }

  @override
  List<String> unmarshal(Uint8List data) {
    final reader = BinaryReaderImpl(data);
    return reader.readStringList();
  }
}
