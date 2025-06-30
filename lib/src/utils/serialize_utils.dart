import "package:json_annotation/json_annotation.dart";
import "package:pinenacl/api.dart";

const uint8Converter = Uint8ListConverter();
const byteListConverter = ByteListConverter();

class Uint8ListConverter implements JsonConverter<Uint8List, List> {
  const Uint8ListConverter();

  @override
  Uint8List fromJson(List json) => Uint8List.fromList(json.cast<int>());

  @override
  List<int> toJson(Uint8List object) => object.cast<int>();
}

class ByteListConverter implements JsonConverter<ByteList, List> {
  const ByteListConverter();

  @override
  ByteList fromJson(List json) => ByteList(json.cast());

  @override
  List<int> toJson(ByteList object) => object.cast<int>();
}
