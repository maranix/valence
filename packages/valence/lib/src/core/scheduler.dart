import 'dart:async';

import 'package:collection/collection.dart';
import 'package:valence/src/core/node/nodes.dart';

abstract interface class NodeScheduler {
  factory NodeScheduler() => _NodeSchedulerImpl();

  void scheduleNode(SchedulableNode node);

  void scheduleNodes(Iterable<SchedulableNode> nodes);
}

final class _NodeSchedulerImpl implements NodeScheduler {
  _NodeSchedulerImpl();

  int _maxDepth = 100;
  int _lowestQueuedDepth = 999999;

  final List<List<SchedulableNode>> _buckets = .filled(100, []);

  bool _flushing = false;

  @override
  void scheduleNode(SchedulableNode node) {
    if (node.isScheduled) return;
    node.isScheduled = true;

    final depth = node.depth;
    _buckets[depth].add(node);

    if (depth < _lowestQueuedDepth) {
      _lowestQueuedDepth = depth;
    }

    _tryFlush();
  }

  @override
  void scheduleNodes(Iterable<SchedulableNode> nodes) {
    for (final node in nodes) {
      if (node.isScheduled) continue;
      node.isScheduled = true;

      final depth = node.depth;
      _buckets[depth].add(node);

      if (depth < _lowestQueuedDepth) {
        _lowestQueuedDepth = depth;
      }
    }

    _tryFlush();
  }

  void _tryFlush() {
    if (_flushing) return;

    scheduleMicrotask(_flush);
  }

  void _flush() {
    if (_flushing) return;

    _flushing = true;

    for (var d = _lowestQueuedDepth; d < _maxDepth; d++) {
      final bucket = _buckets[d];

      while (bucket.isNotEmpty) {
        final node = bucket.removeLast();
        node.isScheduled = false;

        node.refresh();
      }
    }

    _lowestQueuedDepth = 999999;
    _flushing = false;
  }
}
