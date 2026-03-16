import 'package:nucleas/src/context.dart';

typedef AtomMutator<T> = T Function(T val);

abstract interface class Atom<T> {
  factory Atom(T value, {ReactiveContext? context}) = _AtomImpl;

  T value();

  T peek();

  void update(AtomMutator<T> mut);

  void dispose();
}

final class _AtomImpl<T> implements Atom<T> {
  _AtomImpl(this._value, {ReactiveContext? context})
    : _context = context ?? defaultReactiveContext {
    _id = _context.registerNode();
  }

  late final int _id;

  final ReactiveContext _context;

  T _value;

  @override
  T value() {
    _context.trackRead(_id);
    return _value;
  }

  @override
  T peek() => _value;

  @override
  void update(AtomMutator<T> mut) {
    final next = mut(_value);

    // Skip propagation if the value hasn't actually changed.
    if (identical(_value, next) || _value == next) return;

    _value = next;

    final deps = _context.getDependents(_id);
    for (var i = 0; i < deps.length; i++) {
      _context.scheduleUpdate(deps[i]);
    }
  }

  @override
  void dispose() => _context.disposeNode(_id);
}
