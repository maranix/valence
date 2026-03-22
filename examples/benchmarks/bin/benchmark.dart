import 'package:benchmark/valence_bench.dart';
import 'package:benchmark/signals_bench.dart';
import 'package:benchmark/bloc_bench.dart';

void main() {
  print('=== Dispatch (State Creation & Update) ===');
  ValenceDispatchBenchmark().report();
  SignalsDispatchBenchmark().report();
  BlocDispatchBenchmark().report();

  print('\n=== Diamond Dependency ===');
  ValenceDiamondBenchmark().report();
  SignalsDiamondBenchmark().report();
  // Bloc doesn't naturally support diamond dependencies via native API efficiently

  print('\n=== Deep Chain (Depth=10) ===');
  ValenceDeepBenchmark().report();
  SignalsDeepBenchmark().report();

  print('\n=== Broad Fan-out (100 listeners) ===');
  ValenceFanOutBenchmark().report();
  SignalsFanOutBenchmark().report();
  BlocFanOutBenchmark().report();
}
