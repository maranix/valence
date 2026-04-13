import 'package:verion/src/core/base.dart';
import 'package:verion/src/types.dart';

abstract interface class Trigger {
  bool get disposed;

  void dispose();
}

final class TriggerBase extends VerionBase with Parents implements Trigger {
  TriggerBase(
    this._fn, {
    required super.scope,
    super.label,
  }) {
    refresh();
  }

  final void Function(SubscribeCallback sub) _fn;

  // Dynamic Dependency
  //
  // Used for tracking newly subscribed parents when this is refreshed
  List<VerionBase> _subscriptions = [];

  @override
  void refresh() {
    throwOnDisposed("refresh");

    _fn(_subscribe);

    diffSubs(_subscriptions);
    _subscriptions = [];
  }

  S _subscribe<S>(ReadableVerion<S> node) {
    throwOnDisposed("subscribe");

    if (!_subscriptions.contains(node)) {
      _subscriptions.add(node);
    }

    return node.value;
  }
}
