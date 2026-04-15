import 'package:verion/src/core/base.dart';
import 'package:verion/src/core/subscribe_context.dart';
import 'package:verion/src/observer.dart';
import 'package:verion/src/types.dart';
import 'package:verion/src/utils/equality.dart';

abstract interface class Derive<T> implements ReadableVerion<T> {
  void addListener(ValueCallback<T> fn);
  void removeListener(ValueCallback<T> fn);
}

final class DeriveBase<T> extends ReadableVerion<T>
    with Parents, Children, ListenableVerion<T>
    implements Derive<T> {
  DeriveBase(
    this._fn, {
    EqualityCallback<T>? notifyWhen,
    required super.scope,
    super.label,
  }) : _equals = notifyWhen ?? defaultEquals {
    // Notify observer
    VerionObserver.instance?.onDeriveCreated(this);
  }

  final EqualityCallback<T> _equals;

  final T Function(SubscribeContext sub) _fn;

  bool _initialized = false;

  late T _value;

  late final SubscribeContext _subscribeContext = .new((node) {
    throwOnDisposed("subscribe");
    VerionObserver.instance?.onDeriveSubscribed(this, node);
  });

  @override
  T get value {
    throwOnDisposed("read");

    if (!_initialized) {
      _value = _fn(_subscribeContext);
      _initialized = true;

      diffSubs(_subscribeContext.subscriptions);
      _subscribeContext.clearSubscriptions();
    }

    return _value;
  }

  @override
  void refresh() {
    throwOnDisposed("refresh");

    _subscribeContext.executeTeardown();

    final next = _fn(_subscribeContext);

    diffSubs(_subscribeContext.subscriptions);
    _subscribeContext.clearSubscriptions();

    if (_equals(next, value)) return;

    VerionObserver.instance?.onDeriveUpdated(this, _value, next);

    _value = next;

    // Schedule childrens of this node
    if (hasChildren) {
      scope.scheduler.scheduleNodes(children);
    }

    // Schedule listeners of this node to run during post flush operation
    scope.scheduler.schedulePostFlushListener(this);
  }

  @override
  void dispose() {
    VerionObserver.instance?.onDeriveDisposed(this);
    _subscribeContext.dispose();

    super.dispose();
  }
}
