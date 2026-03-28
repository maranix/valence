abstract base class Action<T> {
  const Action({String? debugLabel}) : _debugLabel = debugLabel;

  factory Action.run({required T Function(T) handler, String? debugLabel}) =
      DelegateAction;

  factory Action.batch({required List<Action<T>> actions, String? debugLabel}) =
      BatchAction;

  final String? _debugLabel;

  String get debugLabel => _debugLabel ?? runtimeType.toString();

  T reduce(T state);
}

final class DelegateAction<T> extends Action<T> {
  DelegateAction({required this.handler, super.debugLabel});

  final T Function(T) handler;

  @override
  T reduce(T state) => handler(state);
}

final class BatchAction<T> extends Action<T> {
  BatchAction({required this.actions, super.debugLabel});

  final List<Action<T>> actions;

  @override
  T reduce(T state) {
    var curr = state;
    for (final action in actions) {
      curr = action.reduce(curr);
    }

    return curr;
  }
}
