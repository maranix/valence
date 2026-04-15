import 'package:verion/src/core/base.dart';
import 'package:verion/src/core/subscribe_context.dart';

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

  final void Function(SubscribeContext sub) _fn;

  final SubscribeContext _subscribeContext = .new();

  @override
  void refresh() {
    throwOnDisposed("refresh");

    _subscribeContext.executeTeardown();

    _fn(_subscribeContext);

    diffSubs(_subscribeContext.subscriptions);
    _subscribeContext.clearSubscriptions();
  }

  @override
  void dispose() {
    _subscribeContext.dispose();
    super.dispose();
  }
}
