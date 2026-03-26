import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:valence/src/config.dart';
import 'package:valence/src/engine/scope.dart';
import 'package:valence/types.dart';
import 'package:valence/utils/equality.dart';

// ---------------------------------------------------------------------------
// Interfaces
// ---------------------------------------------------------------------------

/// Represents a node in the dependency graph.
abstract interface class Node {
  bool get isDisposed;

  /// Disposes the node and cleans up any resources it holds.
  void dispose();
}

/// Represents a data source in the dependency graph.
///
/// A [Source] can have multiple [Dependent] nodes attached to it. When the
/// source's value changes, it is responsible for notifying its dependents
/// so they can recompute or update their state.
abstract interface class Source implements Node {
  /// Internal marker used by the Graph for O(1) deduplication.
  int get lastAccessedEpoch;
  set lastAccessedEpoch(int value);

  /// The dependents of this source.
  Iterable<Dependent> get dependents;

  /// Registers a [Dependent] node to receive updates from this source.
  void addDependent(Dependent node);

  /// Unregisters a previously registered [Dependent] node so it no longer
  /// receives updates from this source.
  void removeDependent(Dependent node);

  void notifyDependents();

  /// Reports to the current scope's graph that this source was read.
  void reportRead();
}

/// Represents a node that depends on one or more [Source]s and [Dependent]s.
///
/// A [Dependent] listens to sources and other dependents and reacts to their
/// changes, typically by scheduling a recomputation of its own state.
abstract interface class Dependent implements Node {
  bool get isScheduled;
  set isScheduled(bool value);

  /// The depth of this node in the dependency graph.
  ///
  /// This is used for topological sorting during the update phase to ensure
  /// that all sources are updated before their dependents.
  int get depth;

  /// Recomputes the node's state based on the current values of its sources.
  ///
  /// This method is called by the reactive engine during the update phase.
  void recompute();

  /// Wraps a [computation], tracks any Sources read during its execution,
  /// and automatically updates the dependency subscriptions.
  void executeTracked(VoidCallback computation);
}

// ---------------------------------------------------------------------------
// Base implementations
// ---------------------------------------------------------------------------

/// Base implementation of [Source] that manages dependents, equality checking,
/// scope registration, and disposal.
abstract base class BaseSource<S> implements Source {
  BaseSource({Scope? scope, EqualityCallback<S>? equals})
    : _scope = scope ?? Valence.root,
      _equals = equals ?? defaultEquals {
    _scope.addRoot(this);
  }

  final Scope _scope;
  final EqualityCallback<S> _equals;
  final List<Dependent> _dependents = [];

  int _lastAccessedEpoch = -1;

  bool _isDisposed = false;

  /// The [Scope] this source belongs to.
  @protected
  Scope get scope => _scope;

  /// The equality function used to compare values of type [S].
  @protected
  EqualityCallback<S> get equals => _equals;

  @override
  bool get isDisposed => _isDisposed;

  @override
  int get lastAccessedEpoch => _lastAccessedEpoch;

  @override
  set lastAccessedEpoch(int epoch) => _lastAccessedEpoch = epoch;

  @override
  void reportRead() {
    _scope.graph.record(this);
  }

  @override
  Iterable<Dependent> get dependents => _dependents;

  @override
  void addDependent(Dependent node) => _dependents.add(node);

  @override
  void removeDependent(Dependent node) {
    final i = _dependents.indexOf(node);
    if (i < 0) return;

    _dependents[i] = _dependents.last;
    _dependents.removeLast();
  }

  @override
  void notifyDependents() {
    _scope.schedular.batch(() {
      for (var i = 0; i < _dependents.length; i++) {
        _scope.schedular.enqueue(_dependents[i]);
      }
    });
  }

  @override
  @mustCallSuper
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _dependents.clear();
  }
}

/// Base implementation of [Dependent] that provides scope-bound disposal
/// and automatic source unsubscription via [DependentMixin].
abstract base class BaseDependent with DependentMixin {
  BaseDependent({Scope? scope}) : _internalScope = scope ?? Valence.root;

  final Scope _internalScope;

  bool _isDisposed = false;

  @override
  Scope get scope => _internalScope;

  @override
  bool get isDisposed => _isDisposed;

  @override
  @mustCallSuper
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    unsubscribeFromSources();
  }
}

/// Mixin that implements [Dependent] dependency-tracking behaviour.
///
/// Provides [executeTracked] which records which [Source]s are read during
/// a computation and automatically maintains the subscription set and graph
/// [depth].
mixin DependentMixin implements Dependent {
  Scope get scope;

  int _depth = 0;

  bool _isScheduled = false;

  List<Source> _sources = [];

  @override
  bool get isScheduled => _isScheduled;

  @override
  set isScheduled(bool value) => _isScheduled = value;

  @override
  int get depth => _depth;

  /// Unsubscribes this node from all currently tracked [Source]s.
  @protected
  void unsubscribeFromSources() {
    for (final source in _sources) {
      source.removeDependent(this);
    }
    _sources.clear();
  }

  void _updateSources(List<Source> sources) {
    final derives = sources.whereType<Dependent>();

    if (_sourcesUnchanged(sources)) {
      _updateDepth(derives);
      return;
    }

    for (final old in _sources) {
      if (!sources.contains(old)) {
        old.removeDependent(this);
      }
    }

    for (final newSrc in sources) {
      if (!_sources.contains(newSrc)) {
        newSrc.addDependent(this);
      }
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

  /// Recomputes the [depth] of this node from the maximum depth among
  /// its dependent-typed sources.
  void _updateDepth(Iterable<Dependent> dependents) {
    var maxDepth = 0;

    for (final dependent in dependents) {
      maxDepth = math.max(dependent.depth, maxDepth);
    }

    _depth = maxDepth + 1;
  }

  @override
  void executeTracked(VoidCallback computation) {
    final sources = scope.graph.track(computation);
    _updateSources(sources);
  }
}
