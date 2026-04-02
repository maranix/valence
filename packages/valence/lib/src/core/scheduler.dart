import 'dart:async';

import 'package:valence/src/core/node/nodes.dart';
import 'package:valence/src/core/registry.dart';

abstract interface class NodeScheduler {
  factory NodeScheduler(NodeRegistry registry) => _NodeSchedulerImpl(registry);

  void scheduleNode(int id);
  void scheduleNodes(List<int> ids);
}

final class _NodeSchedulerImpl implements NodeScheduler {
  _NodeSchedulerImpl(this._registry);

  final NodeRegistry _registry;

  final Set<int> _queue = .new();
  final Set<int> _dirtyIds = .new();

  bool _flushing = false;

  @override
  void scheduleNode(int id) {
    if (_dirtyIds.contains(id)) return;

    _queue.add(id);
    _dirtyIds.add(id);

    if (!_flushing) {
      scheduleMicrotask(_flush);
    }
  }

  @override
  void scheduleNodes(List<int> ids) {
    _queue.addAll(ids);

    if (!_flushing) {
      scheduleMicrotask(_flush);
    }
  }

  void _flush() {
    if (_queue.isEmpty) {
      _flushing = false;
      return;
    }

    _flushing = true;

    final batch = _queue.toList();
    _queue.clear();

    batch.sort((a, b) {
      final depthA = _registry.resolveNodeMetadata<ParentNodes>(a)?.depth ?? 0;
      final depthB = _registry.resolveNodeMetadata<ParentNodes>(b)?.depth ?? 0;

      return depthA.compareTo(depthB);
    });

    for (final id in batch) {
      _dirtyIds.remove(id);

      final node = _registry.resolveNode<Refreshable>(id);

      node?.refresh();
    }

    _flush();
  }
}
