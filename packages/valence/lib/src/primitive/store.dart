import 'package:valence/src/engine/node.dart';
import 'package:valence/src/engine/scope.dart';
import 'package:valence/src/primitive/action.dart';
import 'package:valence/types.dart';

Store<S, A> store<S, A extends Action<S>>(
  S initial, {
  Scope? scope,
  EqualityCallback<S>? equals,
}) => Store<S, A>(initial, scope: scope, equals: equals);

final class Store<S, A extends Action<S>> extends BaseSource<S> {
  Store(this._value, {super.scope, super.equals});

  S _value;
  final List<S> _history = [];

  S call() {
    reportRead();
    return _value;
  }

  void dispatch(A action) {
    assert(!isDisposed, 'Cannot dispatch an action to a disposed Store.');
    assert(
      !scope.graph.isTracking,
      'dispatch() called inside a reactive computation.',
    );

    action.onDispatch();

    final next = action.reduce(_value);
    if (equals(_value, next)) return;

    _history.add(_value);
    _value = next;

    notifyDependents();
  }

  void undo() {
    if (_history.isEmpty) return;
    _value = _history.removeLast();

    notifyDependents();
  }
}
