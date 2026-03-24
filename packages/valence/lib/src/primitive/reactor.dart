import 'dart:math' as math;

import 'package:valence/types.dart';

import '../engine/node.dart';
import '../config.dart';
import '../engine/scope.dart';

/// Creates a new [Reactor].
///
/// {@macro valence.Reactor}
Reactor reactor(
  VoidCallback fn, {
  Scope? scope,
}) => Reactor(fn, scope: scope);

/// {@template valence.Reactor}
/// A terminal node in the reactive graph that runs a side effect.
///
/// [Reactor] is a pure [Dependent] — it subscribes to [Source]s
/// during its computation but exposes nothing downstream.
/// Nothing can read from a [Reactor]; it is always a leaf node.
///
/// It reruns its effect whenever any of its [Source]s change,
/// re-subscribing to whatever sources were read during the latest run.
///
/// On recomputation, [Reactor] first probes its existing [Source]s
/// to check stability before committing to a full run — avoiding
/// unnecessary work when the source set has not changed.
/// {@endtemplate}
final class Reactor implements Dependent {
  /// Creates a new [Reactor].
  ///
  /// {@macro valence.Reactor}
  Reactor(this._fn, {Scope? scope}) : _scope = scope ?? Valence.root {
    _scope.registerReactor(this);
    run();
  }

  final Scope _scope;
  final VoidCallback _fn;

  int _depth = 0;

  /// Whether this node's source set is stable from the last run.
  ///
  /// When true, [recompute] will first probe the existing sources
  /// before committing to a full re-run. Set to false whenever
  /// the source set changes.
  bool _isStable = false;

  @override
  bool isPending = false;

  List<Source> _sources = [];

  @override
  int get depth => _depth;

  /// Runs the effect, tracking any [Source]s read during execution.
  ///
  /// After the run, subscribes to any new sources, unsubscribes from
  /// any dropped ones, and updates [depth] based on the new source set.
  void run() {
    _scope.graph.beginTracking();
    try {
      _fn();
    } finally {
      final newDependencies = _scope.graph.endTracking();
      if (!_sourcesUnchanged(newDependencies)) {
        _updateSources(newDependencies);
      }
    }

    _isStable = true;
  }

  @override
  void recompute() {
    if (_isStable) {
      // Probe the existing sources first — if they replay identically
      // there is no need for a full re-run.
      _scope.graph.beginProbe(_sources);
      _fn();
      if (_scope.graph.endProbe(_sources.length)) return;
      _isStable = false;
    }
    run();
  }

  void _updateSources(List<Source> sources) {
    final derives = sources.whereType<Dependent>();

    if (_sourcesUnchanged(sources)) {
      _updateDepth(derives);
      return;
    }

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

  /// Runs the effect, tracking any [Source]s read during execution.
  ///
  /// After the run, subscribes to any new sources, unsubscribes from
  /// any dropped ones, and updates [depth] based on the new source set.
  void _updateDepth(Iterable<Dependent> dependents) {
    var maxDepth = 0;

    for (final dependent in dependents) {
      maxDepth = math.max(dependent.depth, maxDepth);
    }

    _depth = maxDepth + 1;
  }

  void dispose() {
    for (final source in _sources) {
      source.removeDependent(this);
    }
    _sources.clear();
  }
}
