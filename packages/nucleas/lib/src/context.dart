import 'dart:async';

import 'package:nucleas/src/list.dart';
import 'package:nucleas/src/scheduler.dart';

final defaultReactiveContext = ReactiveContext();

abstract interface class ReactiveContext {
  factory ReactiveContext([Scheduler? scheduler]) = _ReactiveContextImpl;

  /// Generates a unique ID for a new Atom, Computed, or Effect
  int registerNode();

  void startTracking(int nodeId);

  void endTracking();

  /// Called by Atom.value() or Computed.value()
  void trackRead(int providerId);

  /// Retrieves dependents for scheduling (used during Atom.update)
  GrowableUint32List getDependents(int nodeId);

  /// Enqueues a node to be processed by the scheduler.
  void scheduleUpdate(int nodeId);

  /// Flushes the queue and executes the updates.
  void flush();

  void registerSchedulableNode(int nodeId, SchedulableNode node);

  void clearDependencies(int nodeId);

  void disposeNode(int nodeId);
}

final class _ReactiveContextImpl implements ReactiveContext {
  _ReactiveContextImpl([Scheduler? scheduler])
    : _scheduler = scheduler ?? Scheduler();

  /// Unique ID for the next Atom, Computed or Effect node
  int _nextNodeId = 1;

  bool _isUpdateScheduled = false;
  bool _isFlushing = false;

  final Scheduler _scheduler;

  // The call stack for nested Computeds/Effects
  final GrowableUint32List _compStack = GrowableUint32List(16);

  // Graph topology: Node ID -> List of Dependent/Dependency IDs
  final Map<int, GrowableUint32List> _dependents = .new();
  final Map<int, GrowableUint32List> _dependencies = .new();

  // Store the mapping of ID to executables
  final Map<int, SchedulableNode> _schedulables = {};

  @override
  int registerNode() {
    final id = _nextNodeId;

    _dependents[id] = .new();
    _dependencies[id] = .new();

    // Increment _nextNodeId
    _nextNodeId += 1;

    return id;
  }

  @override
  void startTracking(int nodeId) => _compStack.add(nodeId);

  @override
  void endTracking() {
    if (_compStack.isEmpty) return;
    _compStack.removeLast();
  }

  @override
  void trackRead(int providerId) {
    if (_compStack.isEmpty) return;

    final consumerId = _compStack.last;

    // These cannot be null because we pre-initialize them in registerNode()
    final providerDependents = _dependents[providerId]!;
    final consumerDependencies = _dependencies[consumerId]!;

    // Bidirectional link (only add if not already present to avoid duplicates)
    if (!providerDependents.contains(consumerId)) {
      providerDependents.add(consumerId);
    }

    if (!consumerDependencies.contains(providerId)) {
      consumerDependencies.add(providerId);
    }
  }

  @override
  GrowableUint32List getDependents(int nodeId) =>
      _dependents[nodeId] ?? .new(0);

  @override
  void scheduleUpdate(int nodeId) {
    final node = _schedulables[nodeId];

    // If it's already in the queue or does not exists, do nothing.
    if (node == null || node.isScheduled) return;

    node.isScheduled = true;

    _scheduler.push(nodeId);

    // Auto-trigger the scheduler if it isn't already running.
    // and we aren't currently in the middle of executing one.
    if (!_isUpdateScheduled && !_isFlushing) {
      _isUpdateScheduled = true;
      scheduleMicrotask(flush);
    }
  }

  @override
  void registerSchedulableNode(int nodeId, SchedulableNode node) {
    _schedulables[nodeId] = node;
  }

  @override
  void flush() {
    // Reset the scheduling flag so future updates can schedule a new microtask
    _isUpdateScheduled = false;
    _isFlushing = true;

    try {
      while (!_scheduler.isEmpty) {
        final id = _scheduler.pop();
        if (id == 0) continue;

        _schedulables[id]?.execute();
      }
    } finally {
      _isFlushing = false;
    }
  }

  @override
  void clearDependencies(int nodeId) {
    final deps = _dependencies[nodeId];

    if (deps == null || deps.isEmpty) return;

    for (var i = 0; i < deps.length; i++) {
      _dependents[deps[i]]?.remove(nodeId);
    }

    deps.clear();
  }

  @override
  void disposeNode(int nodeId) {
    clearDependencies(nodeId);

    _dependents.remove(nodeId);
    _dependencies.remove(nodeId);
    _schedulables.remove(nodeId);
  }
}
