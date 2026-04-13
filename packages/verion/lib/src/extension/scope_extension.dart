import 'package:verion/src/core/derive.dart';
import 'package:verion/src/core/scope.dart';
import 'package:verion/src/core/source.dart';
import 'package:verion/src/core/trigger.dart';
import 'package:verion/src/types.dart';

extension SourceX on VerionScope {
  Source<T, E> source<T, E extends SourceEvent<T>>(
    T value, {
    EqualityCallback<T>? notifyWhen,
    String? label,
  }) => SourceBase(
    value,
    scope: this as Scope,
    notifyWhen: notifyWhen,
    label: label,
  );
}

extension DeriveX on VerionScope {
  Derive<T> derive<T>(
    T Function(SubscribeCallback sub) fn, {
    EqualityCallback<T>? notifyWhen,
    String? label,
  }) => DeriveBase(
    fn,
    scope: this as Scope,
    notifyWhen: notifyWhen,
    label: label,
  );
}

extension TriggerX on VerionScope {
  Trigger trigger(void Function(SubscribeCallback sub) fn, {String? label}) =>
      TriggerBase(fn, label: label, scope: this as Scope);
}

extension BatchX on VerionScope {
  void batch(VoidCallback fn) => (this as Scope).scheduler.batch(fn);
}
