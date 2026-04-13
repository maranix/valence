import 'package:verion/verion.dart';

/// A simple implementation of [SourceEvent] used for testing.
/// This will always set the new value on the source.
class SetValue<T> with SourceEvent<T> {
  SetValue(this.value);

  final T value;

  @override
  T reduce(T state) => value;
}

/// Helper method to create a source and a quick set method.
(Source<T, SetValue<T>>, void Function(T)) createSource<T>(
  VerionScope scope,
  T initialValue, {
  String? label,
}) {
  final s = scope.source<T, SetValue<T>>(initialValue, label: label);
  return (s, (T val) => s.dispatch(SetValue(val)));
}

/// Pumps the microtask queue to allow the scheduler to flush
Future<void> pump() => Future.microtask(() {});
