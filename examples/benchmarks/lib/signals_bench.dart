import 'package:signals_core/signals_core.dart';
import 'package:benchmark_harness/benchmark_harness.dart';

class SignalsDispatchBenchmark extends BenchmarkBase {
  SignalsDispatchBenchmark() : super('Signals: Dispatch');
  late Signal<int> s;

  @override
  void setup() => s = signal<int>(0);

  @override
  void run() => s.value++;
}

class SignalsDiamondBenchmark extends BenchmarkBase {
  SignalsDiamondBenchmark() : super('Signals: Diamond Dependency');
  late Signal<int> s;
  late Computed<int> d1;
  late Computed<int> d2;
  late Computed<int> d3;
  Function? cleanup;
  int runs = 0;

  @override
  void setup() {
    s = signal<int>(0);
    d1 = computed(() => s.value + 1);
    d2 = computed(() => s.value + 2);
    d3 = computed(() => d1.value + d2.value);
    cleanup = effect(() {
      d3.value;
      runs++;
    });
  }

  @override
  void teardown() => cleanup?.call();

  @override
  void run() => s.value++;
}

class SignalsDeepBenchmark extends BenchmarkBase {
  SignalsDeepBenchmark() : super('Signals: Deep Chain (10)');
  late Signal<int> s;
  Function? cleanup;
  int runs = 0;

  @override
  void setup() {
    s = signal<int>(0);
    var current = computed(() => s.value + 1);
    for (var i = 0; i < 9; i++) {
      final prev = current;
      current = computed(() => prev.value + 1);
    }
    cleanup = effect(() {
      current.value;
      runs++;
    });
  }

  @override
  void teardown() => cleanup?.call();

  @override
  void run() => s.value++;
}

class SignalsFanOutBenchmark extends BenchmarkBase {
  SignalsFanOutBenchmark() : super('Signals: Broad Fan-out (100)');
  late Signal<int> s;
  final List<Function> cleanups = [];
  int runs = 0;

  @override
  void setup() {
    s = signal<int>(0);
    for (var i = 0; i < 100; i++) {
      cleanups.add(
        effect(() {
          s.value;
          runs++;
        }),
      );
    }
  }

  @override
  void teardown() {
    for (final c in cleanups) {
      c();
    }
  }

  @override
  void run() => s.value++;
}
