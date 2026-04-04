import 'dart:async';

import 'package:valence/src/core/node/nodes.dart';

abstract interface class NodeScheduler {
  factory NodeScheduler() => _NodeSchedulerImpl();

  void scheduleNode(SchedulableNode node);

  void scheduleNodes(Iterable<SchedulableNode> nodes);

  void batch(void Function() fn);
}

final class _NodeSchedulerImpl implements NodeScheduler {
  _NodeSchedulerImpl();

  int _lowestQueuedDepth = 0;
  int _batchDepth = 0;

  bool _flushing = false;
  bool get _batching => _batchDepth > 0;

  final List<List<SchedulableNode>> _buckets = [];

  @override
  void scheduleNode(SchedulableNode node) {
    if (node.isScheduled) return;
    node.isScheduled = true;

    final depth = node.depth;

    _ensureBucketCapacity(depth);

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

      _ensureBucketCapacity(depth);

      _buckets[depth].add(node);

      if (depth < _lowestQueuedDepth) {
        _lowestQueuedDepth = depth;
      }
    }

    _tryFlush();
  }

  @override
  void batch(void Function() fn) {
    _batchDepth++;

    try {
      fn();
    } finally {
      _batchDepth--;

      if (!_batching) {
        _tryFlush();
      }
    }
  }

  void _ensureBucketCapacity(int depth) {
    while (_buckets.length <= depth) {
      _buckets.add([]);
    }
  }

  void _tryFlush() {
    if (_flushing || _batching) return;

    scheduleMicrotask(_flush);
  }

  void _flush() {
    if (_flushing) return;
    _flushing = true;

    int d = _lowestQueuedDepth;

    while (d < _buckets.length) {
      final bucket = _buckets[d];

      if (bucket.isEmpty) {
        d++;
        _lowestQueuedDepth = d;
        continue;
      }

      final node = bucket.removeLast();
      node.isScheduled = false;

      node.refresh();

      if (_lowestQueuedDepth < d) {
        d = _lowestQueuedDepth;
      }
    }

    _lowestQueuedDepth = _buckets.length;
    _flushing = false;
  }
}
