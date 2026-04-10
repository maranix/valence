import 'package:collection/collection.dart';

final _orderedDeepEquality = DeepCollectionEquality();

bool defaultEquals<T>(T a, T b) {
  if (identical(a, b) || a == b) return true;

  if (a is Iterable || a is Map) {
    return _orderedDeepEquality.equals(a, b);
  }

  return false;
}
