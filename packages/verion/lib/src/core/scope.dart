import 'package:verion/src/core/base.dart';
import 'package:verion/src/core/scheduler.dart';
import 'package:verion/src/observer.dart';

abstract interface class VerionScope {
  factory VerionScope({String? label}) = _ScopeImpl;

  String get label;

  void dispose();
}

abstract interface class Scope implements VerionScope {
  Scheduler get scheduler;

  void registerNode(VerionBase node);
  void removeNode(VerionBase node);
}

final class _ScopeImpl implements Scope {
  _ScopeImpl({String? label, Scheduler? scheduler})
    : _scheduler = scheduler ?? Scheduler(),
      _label = label {
    VerionObserver.instance?.onScopeCreated(this);
  }

  final Scheduler _scheduler;

  @override
  Scheduler get scheduler => _scheduler;

  final String? _label;

  @override
  String get label => _label ?? runtimeType.toString();

  final List<VerionBase> _nodes = [];

  @override
  void registerNode(VerionBase node) => _nodes.add(node);

  @override
  void removeNode(VerionBase node) {
    final idx = _nodes.indexOf(node);
    if (idx == -1) return;

    _nodes[idx] = _nodes.last;
    _nodes.removeLast();
  }

  @override
  void dispose() {
    _scheduler.dispose();
    _nodes.clear();

    VerionObserver.instance?.onScopeDisposed(this);
  }
}
