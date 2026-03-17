import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:valence/valence.dart';

/// Benchmark: creating 1,000 effects.
class EffectCreationBenchmark extends BenchmarkBase {
  EffectCreationBenchmark() : super('Effect.Creation (1,000 effects)');

  late ValenceContext _ctx;
  late Atom<int> _source;

  @override
  void setup() {
    _ctx = ValenceContext();
    _source = Atom(0, context: _ctx);
  }

  @override
  void run() {
    final effects = <Effect>[];
    for (var i = 0; i < 1000; i++) {
      effects.add(Effect(() {
        _source.value();
      }, _ctx));
    }
    for (final e in effects) {
      e.dispose();
    }
  }

  @override
  void teardown() {
    _source.dispose();
  }
}

/// Benchmark: atom update → flush → effect re-run, 10,000 iterations.
class EffectReExecutionBenchmark extends BenchmarkBase {
  EffectReExecutionBenchmark()
    : super('Effect.ReExecution (10,000 update+flush)');

  late ValenceContext _ctx;
  late Atom<int> _source;
  late Effect _effect;
  int _execCount = 0;

  @override
  void setup() {
    _ctx = ValenceContext();
    _source = Atom(0, context: _ctx);
    _effect = Effect(() {
      _source.value();
      _execCount++;
    }, _ctx);
    _execCount = 0;
  }

  @override
  void run() {
    for (var i = 0; i < 10000; i++) {
      _source.update((v) => v + 1, flush: true);
    }
  }

  @override
  void teardown() {
    _effect.dispose();
    _source.dispose();
  }
}

/// Benchmark: disposing 1,000 effects.
class EffectDisposeBenchmark extends BenchmarkBase {
  EffectDisposeBenchmark() : super('Effect.Dispose (1,000 effects)');

  late ValenceContext _ctx;
  late Atom<int> _source;
  late List<Effect> _effects;

  @override
  void setup() {
    _ctx = ValenceContext();
    _source = Atom(0, context: _ctx);
    _effects = [
      for (var i = 0; i < 1000; i++)
        Effect(() {
          _source.value();
        }, _ctx),
    ];
  }

  @override
  void run() {
    for (final e in _effects) {
      e.dispose();
    }
    // Re-create for next iteration.
    _effects = [
      for (var i = 0; i < 1000; i++)
        Effect(() {
          _source.value();
        }, _ctx),
    ];
  }

  @override
  void teardown() {
    for (final e in _effects) {
      e.dispose();
    }
    _source.dispose();
  }
}

void main() {
  print('=== Effect Benchmarks ===\n');

  EffectCreationBenchmark().report();
  EffectReExecutionBenchmark().report();
  EffectDisposeBenchmark().report();
}
