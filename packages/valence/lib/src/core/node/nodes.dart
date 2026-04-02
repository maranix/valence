import 'package:meta/meta.dart';
import 'package:valence/src/constants.dart';
import 'package:valence/src/core/node/action.dart';
import 'package:valence/src/core/scope.dart';

part 'mixin.dart';

/// The universal contract for any node that can be subscribed to.
abstract interface class Listenable<T> {
  int get id;

  T get value;
}

abstract class Node {
  Node({Scope? scope, String? label})
    : _scope = (scope ?? rootScope),
      _label = label {
    _id = _scope.registry.allocateId();
    _scope.registry.registerNode(this);
  }

  final Scope _scope;

  late final int _id;

  /// Id of this Node.
  int get id => _id;

  final String? _label;

  String get label => _label ?? runtimeType.toString();

  bool _disposed = false;

  /// Whether this node was disposed.
  bool get disposed => _disposed;

  /// Marks this node as disposed and tear down its dependents & dependencies
  @mustCallSuper
  void dispose() {
    if (_disposed) return;

    _disposed = true;
    _scope.registry.unregisterNode(this);
  }
}

mixin ListenableNode<T> on Node implements Listenable<T> {
  late T _cachedValue;

  @override
  T get value => _cachedValue;

  void notifyDependents() {
    final dependents = _scope.registry.resolveDependents<Refreshable>(this);

    for (final dep in dependents) {
      _scope.scheduler.scheduleNode(dep.id);
    }
  }
}

mixin Refreshable on Node {
  final Set<int> _currentDeps = .new();

  S _listen<S>(Listenable<S> node) {
    _currentDeps.add(node.id);
    return node.value;
  }

  void _commitDeps() {
    _scope.registry.reconcileDependencies(id, _currentDeps);
    _currentDeps.clear();
  }

  void refresh();
}

abstract base class SourceNode<T, A extends Action<T>> extends Node {
  SourceNode(this._state, {super.scope, super.label});

  T _state;

  Scope get scope => _scope;

  void dispatch(A action) {
    final next = action.reduce(_state);

    if (identical(_state, next)) return;

    _state = next;
    notifyDependents();
  }

  void notifyDependents() {
    final selectors = _scope.registry.resolveDependents<SelectorNode>(this);

    for (final selector in selectors) {
      selector.refresh();
    }
  }
}

abstract base class SelectorNode<T, S> extends Node with ListenableNode<T> {
  SelectorNode(this._store, this._fn, {super.scope, super.label}) {
    _cachedValue = _fn(_store._state);
    _scope.registry.linkSelector(this, _store);
  }

  final SourceNode<S, Action<S>> _store;

  final T Function(S) _fn;

  int get storeId => _store.id;

  void refresh() {
    final nextVal = _fn(_store._state);

    if (identical(nextVal, _cachedValue)) return;

    _cachedValue = nextVal;

    notifyDependents();
  }
}

abstract base class RelayNode<T> extends Node
    with ListenableNode<T>, Refreshable {
  RelayNode(this._fn, {super.scope, super.label}) {
    _cachedValue = _fn(_listen);
    _commitDeps();
  }

  final T Function(S Function<S>(Listenable<S>) sub) _fn;

  @override
  void refresh() {
    _cachedValue = _fn(_listen);

    _commitDeps();
    notifyDependents();
  }
}

abstract base class ObserverNode extends Node with Refreshable {
  ObserverNode(this._fn, {super.scope, super.label}) {
    refresh();
  }

  final void Function(S Function<S>(Listenable<S>) sub) _fn;

  @override
  void refresh() {
    _fn(_listen);
    _commitDeps();
  }
}
