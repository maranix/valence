import 'dart:async';

import 'package:verion/src/core/base.dart';
import 'package:verion/src/core/core.dart';
import 'package:verion/src/types.dart';

abstract interface class Scheduler {
  factory Scheduler() = _SchedulerImpl;

  void scheduleNode(VerionBase node);
  void scheduleNodes(Iterable<VerionBase> nodes);
  void schedulePostFlushListener(ListenableVerion nodes);
  void batch(VoidCallback fn);
  void flush();
  void dispose();
}

final class _SchedulerImpl implements Scheduler {
  int _lowestDepth = 0;
  int _batchDepth = 0;

  bool get _batching => _batchDepth > 0;

  bool _flushing = false;
  bool _flushScheduled = false;

  final List<List<VerionBase>> _buckets = [];
  final Set<ListenableVerion> _listeners = .new();

  int _queuedNodes = 0;

  @override
  void scheduleNode(VerionBase node) {
    _queueNode(node);

    _tryFlush();
  }

  @override
  void scheduleNodes(Iterable<VerionBase> nodes) {
    for (final node in nodes) {
      _queueNode(node);
    }

    _tryFlush();
  }

  @override
  void schedulePostFlushListener(ListenableVerion node) {
    if (node.disposed || _listeners.contains(node)) return;

    _listeners.add(node);

    _tryFlush();
  }

  @override
  void batch(VoidCallback fn) {
    _batchDepth += 1;

    try {
      fn();
    } finally {
      _batchDepth -= 1;

      if (!_batching) {
        _tryFlush();
      }
    }
  }

  @override
  void flush() {
    if (_flushing) return;

    _flushing = true;
    _flushScheduled = false;

    int i = 0;
    int d = _lowestDepth;

    try {
      while (_queuedNodes > 0 && d < _buckets.length) {
        final bucket = _buckets[d];

        // If this bucket is empty move to the next one
        if (bucket.isEmpty) {
          d += 1;
          _lowestDepth = d;
          continue;
        }

        final node = bucket.removeLast();
        _queuedNodes -= 1;

        if (i > 100_000) {
          throw VerionCircularDependencyDetected(node);
        }

        if (node.disposed) continue;

        node.refresh();
        node.dirty = false;

        // If a new node was queued at a lower at a depth during flush
        // rewind back and start flushing from [_lowestDepth] to maintain consistency
        if (_lowestDepth < d) {
          d = _lowestDepth;
        }

        i += 1;
      }
    } finally {
      _flushing = false;
      _lowestDepth = 0;
      _queuedNodes = 0;

      for (final listener in _listeners) {
        listener.notifyListeners();
      }

      _listeners.clear();
    }
  }

  @override
  void dispose() {
    _batchDepth = 0;
    _lowestDepth = 0;
    _flushing = false;
    _flushScheduled = false;

    _listeners.clear();
    _buckets.clear();
  }

  @pragma("prefer-inline")
  void _tryFlush() {
    if (_flushing || _batching || _flushScheduled) return;

    _flushScheduled = true;

    scheduleMicrotask(flush);
  }

  @pragma("prefer-inline")
  void _ensureBucketCapacity(int depth) {
    while (depth >= _buckets.length) {
      _buckets.add([]);
    }
  }

  @pragma("prefer-inline")
  void _updateLowestDepth(int depth) {
    if (_queuedNodes == 0 || depth < _lowestDepth) {
      _lowestDepth = depth;
    }
  }

  @pragma("prefer-inline")
  void _queueNode(VerionBase node) {
    if (node.disposed || node.dirty) return;

    final depth = node.depth;

    _ensureBucketCapacity(depth);
    _updateLowestDepth(depth);

    _buckets[depth].add(node);
    node.dirty = true;
    _queuedNodes += 1;
  }
}
