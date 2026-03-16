import 'dart:typed_data';

/// An internal interface for nodes that can be executed by the scheduler.
abstract interface class SchedulableNode {
  bool get isScheduled;

  set isScheduled(bool value);

  // Called by the scheduler during a flush.
  void execute();
}

abstract interface class Scheduler {
  factory Scheduler([int capacity = 1024]) =>
      _RingBufferSchedularImpl(capacity);

  bool get isEmpty;

  bool get isFull;

  /// Enqueues a node ID
  void push(int nodeId);

  /// Dequeues the node ID.
  ///
  /// Returns `0` if the buffer is empty.
  int pop();

  /// Resets the buffer.
  void clear();
}

final class _RingBufferSchedularImpl implements Scheduler {
  _RingBufferSchedularImpl(int capacity)
    : assert(
        (capacity > 0) && ((capacity & capacity - 1) == 0),
        "RingBuffer capacity must be a power of two.",
      ),
      _data = .new(capacity),
      _mask = capacity - 1;

  final Uint32List _data;
  final int _mask;

  int _head = 0;
  int _tail = 0;

  @override
  bool get isEmpty => _head == _tail;

  @override
  bool get isFull => (_tail - _head) == _data.length;

  @override
  void push(int nodeId) {
    if (isFull) {
      throw StateError(
        'RingBuffer overflow: Reactive update burst exceeded capacity.',
      );
    }

    _data[_tail & _mask] = nodeId;
    _tail += 1;
  }

  @override
  int pop() {
    if (isEmpty) return 0;

    final nodeId = _data[_head & _mask];

    _head += 1;

    return nodeId;
  }

  @override
  void clear() {
    _head = 0;
    _tail = 0;
  }
}
