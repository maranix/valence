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

final List<CounterStoreEvent> actions = [
  .increment,
  .increment,
  .decrement,
  .increment,
  .increment,
  .increment,
];

void main() async {
  final countStore = source<int, CounterStoreEvent>(0);

  final countSquared = derive((sub) {
    final count = sub(countStore);
    return count * 2;
  });

  observe((sub) {
    final count = sub(countStore);
    final squaredCount = sub(countSquared);

    print("Count: $count\tSquared:$squaredCount");
  });

  while (actions.isNotEmpty) {
    countStore.dispatch(actions.removeLast());

    await Future.delayed(.new(seconds: 1));
  }
}
