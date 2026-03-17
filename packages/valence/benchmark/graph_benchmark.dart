import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:valence/valence.dart';

/// Benchmark: 1 atom → 100 effects (wide fan-out), update + flush.
class WideGraphBenchmark extends BenchmarkBase {
  WideGraphBenchmark() : super('Graph.Wide (1 atom → 100 effects)');

  late ValenceContext _ctx;
  late Atom<int> _source;
  late List<Effect> _effects;

  @override
  void setup() {
    _ctx = ValenceContext();
    _source = Atom(0, context: _ctx);
    _effects = [
      for (var i = 0; i < 100; i++)
        Effect(() {
          _source.value();
        }, _ctx),
    ];
  }

  @override
  void run() {
    _source.update((v) => v + 1, flush: true);
  }

  @override
  void teardown() {
    for (final e in _effects) {
      e.dispose();
    }
    _source.dispose();
  }
}

/// Benchmark: 100-level deep chain — atom → computed₁ → … → computed₁₀₀ → effect.
class DeepGraphBenchmark extends BenchmarkBase {
  DeepGraphBenchmark()
    : super('Graph.Deep (atom → 100 computed → effect)');

  late ValenceContext _ctx;
  late Atom<int> _source;
  late List<Computed<int>> _chain;
  late Effect _effect;

  @override
  void setup() {
    _ctx = ValenceContext();
    _source = Atom(0, context: _ctx);

    _chain = [];
    Computed<int> prev = Computed(() => _source.value(), context: _ctx);
    _chain.add(prev);
    for (var i = 1; i < 100; i++) {
      final upstream = prev;
      final next = Computed(() => upstream.value() + 1, context: _ctx);
      _chain.add(next);
      prev = next;
    }

    final tail = _chain.last;
    _effect = Effect(() {
      tail.value();
    }, _ctx);
  }

  @override
  void run() {
    _source.update((v) => v + 1, flush: true);
  }

  @override
  void teardown() {
    _effect.dispose();
    for (final c in _chain.reversed) {
      c.dispose();
    }
    _source.dispose();
  }
}

/// Benchmark: diamond-shaped dependency graph.
///
/// ```
///   a1   a2
///    \  /
///     c1     (computed: a1 + a2)
///     |
///     e1     (effect: reads c1)
/// ```
///
/// Updates both atoms, then flushes. The effect should run only once per flush.
class DiamondGraphBenchmark extends BenchmarkBase {
  DiamondGraphBenchmark() : super('Graph.Diamond (2 atoms → computed → effect)');

  late ValenceContext _ctx;
  late Atom<int> _a1;
  late Atom<int> _a2;
  late Computed<int> _c1;
  late Effect _effect;

  @override
  void setup() {
    _ctx = ValenceContext();
    _a1 = Atom(0, context: _ctx);
    _a2 = Atom(0, context: _ctx);
    _c1 = Computed(() => _a1.value() + _a2.value(), context: _ctx);
    _effect = Effect(() {
      _c1.value();
    }, _ctx);
  }

  @override
  void run() {
    for (var i = 0; i < 1000; i++) {
      _a1.update((v) => v + 1);
      _a2.update((v) => v + 1);
      _ctx.flush();
    }
  }

  @override
  void teardown() {
    _effect.dispose();
    _c1.dispose();
    _a1.dispose();
    _a2.dispose();
  }
}

/// Benchmark: dynamic dependencies — an effect that conditionally reads
/// different atoms based on a selector.
class DynamicDependenciesBenchmark extends BenchmarkBase {
  DynamicDependenciesBenchmark()
    : super('Graph.DynamicDeps (conditional reads)');

  late ValenceContext _ctx;
  late Atom<bool> _selector;
  late Atom<int> _branchA;
  late Atom<int> _branchB;
  late Effect _effect;

  @override
  void setup() {
    _ctx = ValenceContext();
    _selector = Atom(true, context: _ctx);
    _branchA = Atom(0, context: _ctx);
    _branchB = Atom(0, context: _ctx);

    _effect = Effect(() {
      if (_selector.value()) {
        _branchA.value();
      } else {
        _branchB.value();
      }
    }, _ctx);
  }

  @override
  void run() {
    for (var i = 0; i < 5000; i++) {
      // Toggle the selector and update the active branch.
      _selector.update((v) => !v, flush: true);
      if (_selector.peek()) {
        _branchA.update((v) => v + 1, flush: true);
      } else {
        _branchB.update((v) => v + 1, flush: true);
      }
    }
  }

  @override
  void teardown() {
    _effect.dispose();
    _branchA.dispose();
    _branchB.dispose();
    _selector.dispose();
  }
}

void main() {
  print('=== Graph Benchmarks ===\n');

  WideGraphBenchmark().report();
  DeepGraphBenchmark().report();
  DiamondGraphBenchmark().report();
  DynamicDependenciesBenchmark().report();
}
