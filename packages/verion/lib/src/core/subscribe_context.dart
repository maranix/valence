import 'package:meta/meta.dart';
import 'package:verion/src/core/base.dart';
import 'package:verion/src/types.dart';

abstract interface class SubscribeContext {
  factory SubscribeContext([void Function(ReadableVerion)? onSubscribe]) =
      _SubscribeContextImpl;

  List<VerionBase> get subscriptions;

  T call<T>(ReadableVerion<T> node);

  void onDispose(VoidCallback teardown);

  @internal
  void executeTeardown();

  @internal
  void clearSubscriptions();

  @mustBeOverridden
  void dispose();
}

final class _SubscribeContextImpl implements SubscribeContext {
  _SubscribeContextImpl([this._onSubscribe]);

  final void Function(ReadableVerion)? _onSubscribe;

  List<VerionBase> _subscriptions = [];

  @override
  List<VerionBase> get subscriptions => _subscriptions;

  VoidCallback? _teardownCallback;

  @override
  T call<T>(ReadableVerion<T> node) {
    if (!_subscriptions.contains(node)) {
      _subscriptions.add(node);
    }

    _onSubscribe?.call(node);

    return node.value;
  }

  @override
  void onDispose(VoidCallback teardown) {
    _teardownCallback = teardown;
  }

  @override
  void executeTeardown() {
    _teardownCallback?.call();
    _teardownCallback = null;
  }

  @override
  void clearSubscriptions() {
    _subscriptions = [];
  }

  @override
  void dispose() {
    executeTeardown();
    clearSubscriptions();
  }
}
