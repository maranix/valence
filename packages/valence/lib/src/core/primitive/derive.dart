import 'package:valence/src/core/node/nodes.dart';
import 'package:valence/src/core/scope.dart';

Derive<T> derive<T>(
  T Function(S Function<S>(Listenable<S>)) fn, {
  Scope? scope,
  String? label,
}) => _DeriveImpl(fn, scope: scope, label: label);

abstract interface class Derive<T> implements Listenable<T> {
  T call();

  void addListener(void Function(T) fn);

  void removeListener(void Function(T) fn);

  void dispose();
}

final class _DeriveImpl<T> extends RelayNode<T> implements Derive<T> {
  _DeriveImpl(super.fn, {super.scope, super.label});

  @override
  T call() => value;
}
