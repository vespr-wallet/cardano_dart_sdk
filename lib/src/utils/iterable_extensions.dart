import "dart:collection";

UnmodifiableListView<T> emptyUnmodifiableList<T>() => UnmodifiableListView([]);

extension IterableX<T> on Iterable<T> {
  OUT reduceSafe<OUT>({required OUT Function(OUT aggregator, T e) combine, required OUT initialValue}) {
    final Iterator<T> iterator = this.iterator;
    OUT aggregator = initialValue;

    while (iterator.moveNext()) {
      aggregator = combine(aggregator, iterator.current);
    }
    return aggregator;
  }

  Iterable<T> withoutLast() => length > 0 ? take(length - 1) : this;

  List<T> replaceLast(T newLast) {
    if (length == 0) throw Exception("Cannot call replaceLast on empty list");
    return withoutLast().toList() + [newLast];
  }

  Iterable<T> plusElementIf(T newElement, bool condition) => condition ? toList() + [newElement] : this;

  UnmodifiableListView<T> get asUnmodifiableList => UnmodifiableListView(this);
}

extension ListExtensions<T> on List<T> {
  List<T> plusElementIF(T newElement, bool condition) => condition ? this + [newElement] : this;
}
