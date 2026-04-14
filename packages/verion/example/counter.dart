import 'package:verion/verion.dart';

enum CounterStoreEvent implements SourceEvent<int> {
  increment,
  decrement
  ;

  @override
  int reduce(int count) => switch (this) {
    .increment => count + 1,
    .decrement => count + 1,
  };
}

final class CounterScope extends VerionScope {}

final List<CounterStoreEvent> actions = [
  .increment,
  .increment,
  .decrement,
  .increment,
  .increment,
  .increment,
];

void main() async {
  final scope = CounterScope();
  final countStore = scope.source<int, CounterStoreEvent>(0);

  final countSquared = scope.derive((sub) {
    final count = sub(countStore);
    return count * 2;
  });

  scope.trigger((sub) {
    final count = sub(countStore);
    final squaredCount = sub(countSquared);

    print("Count: $count\tSquared:$squaredCount");
  });

  while (actions.isNotEmpty) {
    countStore.dispatch(actions.removeLast());

    await Future.delayed(.new(seconds: 1));
  }

  scope.dispose();
}
