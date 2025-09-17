import "package:cardano_dart_types/cardano_dart_types.dart";
import "package:collection/collection.dart";
import "package:meta/meta.dart";
import "package:pinenacl/api.dart";

@immutable
class CardanoSigner {
  static const _listEquality = ListEquality<int>();

  final ByteList publicKeyBytes;
  final Uint8List requestedSignerBytes; // address/drep bytes
  final CardanoSigningPath_Shelley path;

  const CardanoSigner({
    required this.publicKeyBytes,
    required this.requestedSignerBytes,
    required this.path,
  });

  @override
  String toString() {
    return "CardanoSigner(publicKeyBytes: ${publicKeyBytes.hexEncode()}, requestedSignerBytes: ${requestedSignerBytes.hexEncode()}, path: $path)";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CardanoSigner &&
        _listEquality.equals(publicKeyBytes, other.publicKeyBytes) &&
        _listEquality.equals(requestedSignerBytes, other.requestedSignerBytes) &&
        other.path == path;
  }

  @override
  int get hashCode => Object.hash(publicKeyBytes, requestedSignerBytes, path);

  static CardanoSigner unmarshal(Uint8List bytes) {
    final reader = BinaryReaderImpl(bytes);
    final publicKeyBytes = reader.readByteList();
    final requestedSignerBytes = reader.readByteList();

    final path = CardanoSigningPath_Shelley(
      account: reader.readInt(),
      address: reader.readInt(),
      role: Bip32KeyRole.fromDerivationIndex(reader.readInt()),
    );
    return CardanoSigner(
      publicKeyBytes: ByteList(publicKeyBytes),
      requestedSignerBytes: requestedSignerBytes,
      path: path,
    );
  }

  Uint8List marshal() {
    final writer = BinaryWriterImpl();
    writer.writeByteList(publicKeyBytes.toUint8List());
    writer.writeByteList(requestedSignerBytes);

    // start of CardanoSigningPath_Shelley
    writer.writeInt(path.account);
    writer.writeInt(path.address);
    writer.writeInt(path.role.derivationIndex);
    // end of CardanoSigningPath_Shelley
    return writer.toBytes();
  }
}
