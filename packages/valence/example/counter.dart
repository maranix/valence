import 'package:valence/valence.dart';

final class CountIncrement extends Action<int> {
  const CountIncrement();

  @override
  int reduce(int state) => state + 1;
}

final class CountDecrement extends Action<int> {
  const CountDecrement();

  @override
  int reduce(int state) => state - 1;
}

final actions = [
  const CountIncrement(),
  const CountIncrement(),
  const CountDecrement(),
  const CountIncrement(),
  const CountIncrement(),
  const CountIncrement(),
];

void main() async {
  final countStore = store(0);
  final countSelector = countStore.select((c) => c);

  final countSquared = derive((sub) {
    final count = sub(countSelector);
    return count * 2;
  });

  watch((sub) {
    final count = sub(countSelector);
    final squaredCount = sub(countSquared);

    print("Count: $count\tSquared:$squaredCount");
  });

  while (actions.isNotEmpty) {
    countStore.dispatch(actions.removeLast());

    await Future.delayed(.new(seconds: 1));
  }
}
