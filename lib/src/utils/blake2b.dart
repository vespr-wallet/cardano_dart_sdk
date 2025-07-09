import "package:pinenacl/digests.dart";
import "package:pinenacl/encoding.dart";

///
/// Base blake2b hash function can produce hashes of arbirary size.
///
Uint8List blake2bHash(List<int> stringBytes, {required int digestSize}) =>
    Hash.blake2b(Uint8List.fromList(stringBytes), digestSize: digestSize);

Uint8List blake2bHash160(List<int> stringBytes) => blake2bHash(stringBytes, digestSize: 20);

Uint8List blake2bHash224(List<int> stringBytes) => blake2bHash(stringBytes, digestSize: 28);

Uint8List blake2bHash256(List<int> stringBytes) => blake2bHash(stringBytes, digestSize: 32);
