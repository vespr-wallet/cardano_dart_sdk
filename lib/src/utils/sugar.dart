extension Sugar<T> on T {
  void also(Function(T) invoker) => invoker(this);

  Y let<Y>(Y Function(T) invoker) => invoker(this);

  Y tryCatch<Y>({required Y Function(T data) t, required Y Function(T data) c}) {
    try {
      return t(this);
    } catch (err) {
      return c(this);
    }
  }
}

extension ExtraSugar<T> on T? {
  T require({String? argumentName}) {
    if (this != null) {
      return this!;
    } else {
      throw ArgumentError("Expected non null", argumentName);
    }
  }
}

extension StringExtensions on String {
  String take(int i) => length > i ? substring(0, i) : this;

  String drop(int i) => length > i ? substring(i) : "";

  String ellipsise(int maxLen) => length > maxLen ? "${substring(0, maxLen)}..." : this;

  String ellipsiseMiddle(int maxLen) {
    final lenEachSide = maxLen ~/ 2;
    return length > maxLen ? "${substring(0, lenEachSide)}...${substring(length - lenEachSide)}" : this;
  }
}
