import 'package:valence/types.dart';
import 'package:valence/utils/equality.dart';

import 'core.dart';
import 'scope.dart';

final class Derive<T> implements ReactiveNode {
  Derive(this._scope, this._compute, {EqualityCallback<T>? equals})
    : _equals = equals ?? defaultEquals {
    _scope.beginTracking();
    try {
      _cachedValue = _compute();
    } finally {
      final deps = _scope.endTracking();
      _updateDeps(deps);
    }
  }

  final Scope _scope;
  final ValueCallback<T> _compute;
  final EqualityCallback<T> _equals;

  T? _cachedValue;
  int _depth = 0;

  List<Node> _dependencies = [];
  final List<ReactiveNode> _dependents = [];

  @override
  bool isPending = false;

  @override
  int get depth => _depth;

  @override
  void addDependent(ReactiveNode node) => _dependents.add(node);

  @override
  void removeDependent(ReactiveNode node) => _dependents.remove(node);

  T call() {
    _scope.recordRead(this);
    return _cachedValue as T;
  }

  @override
  void recompute() {
    _scope.beginTracking();
    late T next;
    try {
      next = _compute();
    } finally {
      final newDeps = _scope.endTracking();
      _updateDeps(newDeps);
    }

    if (_equals(_cachedValue as T, next)) return;

    _cachedValue = next;

    for (var i = 0; i < _dependents.length; i++) {
      _scope.enqueue(_dependents[i]);
    }
  }

  void _updateDeps(List<Node> newDeps) {
    for (var i = 0; i < _dependencies.length; i++) {
      final dep = _dependencies[i];
      if (!newDeps.contains(dep)) {
        dep.removeDependent(this);
      }
    }
    var maxDepth = 0;
    for (var i = 0; i < newDeps.length; i++) {
      final dep = newDeps[i];
      if (!_dependencies.contains(dep)) {
        dep.addDependent(this);
      }
      final d = dep is ReactiveNode ? dep.depth : 0;
      if (d > maxDepth) maxDepth = d;
    }
    _dependencies = newDeps;
    _depth = maxDepth + 1;
  }

  void dispose() {
    for (final dep in _dependencies) {
      dep.removeDependent(this);
    }

    _dependencies.clear();
    _dependents.clear();
  }
}
