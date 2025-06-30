// ignore_for_file: file_names

class CborDeserializationException implements Exception {
  final String message;

  const CborDeserializationException(this.message);

  @override
  String toString() => message;
}
