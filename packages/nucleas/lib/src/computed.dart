import 'package:nucleas/src/context.dart';
import 'package:nucleas/src/scheduler.dart';

abstract interface class Computed<T> implements SchedulableNode {
  factory Computed(T Function() computeFn, [ReactiveContext? context]) =
      _ComputedSchedulableNodeImpl;

  T value();

  void dispose();
}

final class _ComputedSchedulableNodeImpl<T> implements Computed<T> {
  _ComputedSchedulableNodeImpl(
    T Function() computeFn, [
    ReactiveContext? context,
  ]) : _fn = computeFn,
       _context = context ?? defaultReactiveContext {
    _id = _context.registerNode();
    _context.registerSchedulableNode(_id, this);

    _recompute();
  }

  final T Function() _fn;

  final ReactiveContext _context;

  late final int _id;

  late T _cached;

  bool _dirty = false;

  bool _isScheduled = false;

  void _recompute() {
    _context.clearDependencies(_id);

    _context.startTracking(_id);
    try {
      _cached = _fn();
      _dirty = false;
    } finally {
      _context.endTracking();
    }
  }

  @override
  bool get isScheduled => _isScheduled;

  @override
  set isScheduled(bool value) {
    _isScheduled = value;
  }

  @override
  T value() {
    // Register that whoever is currently running depends on this Computed
    _context.trackRead(_id);

    if (_dirty) _recompute();

    // Return the cached value
    return _cached;
  }

  @override
  void execute() {
    isScheduled = false;

    if (_dirty) return;
    _dirty = true;

    final deps = _context.getDependents(_id);
    for (var i = 0; i < deps.length; i++) {
      _context.scheduleUpdate(deps[i]);
    }
  }

  @override
  void dispose() => _context.disposeNode(_id);
}
