import 'dart:math' as math;
import 'package:valence/types.dart';
import 'package:valence/utils/equality.dart';

import '../engine/node.dart';
import '../config.dart';
import '../engine/scope.dart';

Derive<T> derive<T>(
  ValueCallback<T> fn, {
  Scope? scope,
  EqualityCallback<T>? equals,
}) => Derive<T>(fn, scope: scope, equals: equals);

final class Derive<T> implements Source, Dependent {
  Derive(this._compute, {Scope? scope, EqualityCallback<T>? equals})
    : _scope = scope ?? Valence.root,
      _equals = equals ?? defaultEquals {
    _scope.registerDerive(this);
    _cachedValue = _retrackAndCompute();
  }

  final Scope _scope;
  final ValueCallback<T> _compute;
  final EqualityCallback<T> _equals;

  T? _cachedValue;
  int _depth = 0;

  bool _isStable = false;

  List<Source> _sources = [];
  final List<Dependent> _dependents = [];

  @override
  bool isPending = false;

  @override
  int get depth => _depth;

  @override
  void addDependent(Dependent node) => _dependents.add(node);

  @override
  void removeDependent(Dependent node) => _dependents.remove(node);

  T call() {
    _scope.graph.recordSource(this);
    return _cachedValue as T;
  }

  @override
  void recompute() {
    final next = switch (_isStable) {
      true => _compute(),
      false => _retrackAndCompute(),
    };

    if (_equals(_cachedValue as T, next)) return;
    _cachedValue = next;

    for (var i = 0; i < _dependents.length; i++) {
      _scope.schedular.enqueue(_dependents[i]);
    }
  }

  T _retrackAndCompute() {
    _scope.graph.beginTracking();

    try {
      return _compute();
    } finally {
      final newDependencies = _scope.graph.endTracking();
      if (!_sourcesUnchanged(newDependencies)) {
        _updateSources(newDependencies);
        _isStable = false;
      } else {
        _isStable = true;
      }
    }
  }

  void _updateSources(List<Source> sources) {
    final derives = sources.whereType<Dependent>();
    final newSet = sources.toSet();
    final oldSet = _sources.toSet();

    for (final dep in newSet) {
      if (!oldSet.contains(dep)) dep.addDependent(this);
    }

    for (final dep in oldSet) {
      if (!newSet.contains(dep)) dep.removeDependent(this);
    }

    _sources = sources;
    _updateDepth(derives);
  }

  bool _sourcesUnchanged(List<Source> sources) {
    if (sources.length != _sources.length) return false;

    for (var i = 0; i < sources.length; i++) {
      if (!identical(sources[i], _sources[i])) return false;
    }

    return true;
  }

  void _updateDepth(Iterable<Dependent> dependencies) {
    var maxDepth = 0;

    for (final dep in dependencies) {
      maxDepth = math.max(maxDepth, dep.depth);
    }

    _depth = maxDepth + 1;
  }

  void dispose() {
    for (final source in _sources) {
      source.removeDependent(this);
    }

    _sources.clear();
    _dependents.clear();
  }
}
