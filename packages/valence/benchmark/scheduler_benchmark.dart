import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:valence/valence.dart';

/// Benchmark: 10,000 push/pop cycles on a fixed-capacity scheduler.
class SchedulerPushPopBenchmark extends BenchmarkBase {
  SchedulerPushPopBenchmark()
    : super('Scheduler.PushPop (10,000 cycles, fixed)');

  late Scheduler _scheduler;

  @override
  void setup() {
    _scheduler = Scheduler(1024, SchedulerCapacity.fixed);
  }

  @override
  void run() {
    for (var i = 0; i < 10000; i++) {
      _scheduler.push(i + 1); // node IDs start at 1
      _scheduler.pop();
    }
  }
}

/// Benchmark: fill entire fixed buffer (1024), then drain it.
class SchedulerFillDrainBenchmark extends BenchmarkBase {
  SchedulerFillDrainBenchmark()
    : super('Scheduler.FillDrain (1024 fill+drain)');

  late Scheduler _scheduler;

  @override
  void setup() {
    _scheduler = Scheduler(1024, SchedulerCapacity.fixed);
  }

  @override
  void run() {
    // Fill.
    for (var i = 0; i < 1024; i++) {
      _scheduler.push(i + 1);
    }
    // Drain.
    while (!_scheduler.isEmpty) {
      _scheduler.pop();
    }
  }
}

/// Benchmark: 10,000 push/pop cycles on a growable scheduler.
class GrowableSchedulerPushPopBenchmark extends BenchmarkBase {
  GrowableSchedulerPushPopBenchmark()
    : super('Scheduler.PushPop (10,000 cycles, growable)');

  late Scheduler _scheduler;

  @override
  void setup() {
    _scheduler = Scheduler(1024, SchedulerCapacity.growable);
  }

  @override
  void run() {
    for (var i = 0; i < 10000; i++) {
      _scheduler.push(i + 1);
      _scheduler.pop();
    }
  }
}

void main() {
  print('=== Scheduler Benchmarks ===\n');

  SchedulerPushPopBenchmark().report();
  SchedulerFillDrainBenchmark().report();
  GrowableSchedulerPushPopBenchmark().report();
}
