import 'package:nucleas/src/context.dart';
import 'package:nucleas/src/scheduler.dart';

abstract interface class Effect implements SchedulableNode {
  factory Effect(void Function() effectFn, [ReactiveContext? context]) =
      _EffectSchedulableNodeImpl;

  void dispose();
}

final class _EffectSchedulableNodeImpl implements Effect {
  _EffectSchedulableNodeImpl(
    void Function() effectFn, [
    ReactiveContext? context,
  ]) : _fn = effectFn,
       _context = context ?? defaultReactiveContext {
    _id = _context.registerNode();

    _context.registerSchedulableNode(_id, this);

    // Run immediately to establish dependencies
    execute();
  }

  final void Function() _fn;

  final ReactiveContext _context;

  late final int _id;

  bool _isScheduled = false;

  @override
  bool get isScheduled => _isScheduled;

  @override
  set isScheduled(bool value) {
    _isScheduled = value;
  }

  @override
  void execute() {
    isScheduled = false;

    _context.clearDependencies(_id);

    _context.startTracking(_id);

    try {
      _fn();
    } finally {
      _context.endTracking();
    }
  }

  @override
  void dispose() {
    _context.disposeNode(_id);
  }
}
