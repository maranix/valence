import 'package:bloc/bloc.dart';
import 'package:benchmark_harness/benchmark_harness.dart';
import 'dart:async';

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
}

class BlocDispatchBenchmark extends BenchmarkBase {
  BlocDispatchBenchmark() : super('Bloc: Dispatch');
  late CounterCubit c;

  @override
  void setup() => c = CounterCubit();

  @override
  void teardown() => c.close();

  @override
  void run() => c.increment();
}

class BlocFanOutBenchmark extends BenchmarkBase {
  BlocFanOutBenchmark() : super('Bloc: Broad Fan-out (100)');
  late CounterCubit c;
  final List<StreamSubscription> subs = [];
  int runs = 0;

  @override
  void setup() {
    c = CounterCubit();
    for (var i = 0; i < 100; i++) {
      subs.add(
        c.stream.listen((_) {
          runs++;
        }),
      );
    }
  }

  @override
  void teardown() {
    for (final s in subs) {
      s.cancel();
    }
    c.close();
  }

  @override
  void run() => c.increment();
}
