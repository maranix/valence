import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:valence/valence.dart';

/// Benchmark: creating 1,000 computed nodes.
class ComputedCreationBenchmark extends BenchmarkBase {
  ComputedCreationBenchmark() : super('Computed.Creation (1,000 nodes)');

  late ValenceContext _ctx;
  late Atom<int> _source;

  @override
  void setup() {
    _ctx = ValenceContext();
    _source = Atom(0, context: _ctx);
  }

  @override
  void run() {
    final nodes = <Computed<int>>[];
    for (var i = 0; i < 1000; i++) {
      nodes.add(Computed(() => _source.value() + i, context: _ctx));
    }
    for (final c in nodes) {
      c.dispose();
    }
  }

  @override
  void teardown() {
    _source.dispose();
  }
}

/// Benchmark: reading a cached (clean) computed 10,000 times.
class ComputedReadCleanBenchmark extends BenchmarkBase {
  ComputedReadCleanBenchmark() : super('Computed.ReadClean (10,000 reads)');

  late ValenceContext _ctx;
  late Atom<int> _source;
  late Computed<int> _computed;

  @override
  void setup() {
    _ctx = ValenceContext();
    _source = Atom(42, context: _ctx);
    _computed = Computed(() => _source.value() * 2, context: _ctx);
    // Prime the cache.
    _computed.value();
  }

  @override
  void run() {
    for (var i = 0; i < 10000; i++) {
      _computed.value();
    }
  }

  @override
  void teardown() {
    _computed.dispose();
    _source.dispose();
  }
}

/// Benchmark: invalidate + read cycle (dirty → recompute) 10,000 times.
class ComputedRecomputeBenchmark extends BenchmarkBase {
  ComputedRecomputeBenchmark()
    : super('Computed.Recompute (10,000 invalidate+read)');

  late ValenceContext _ctx;
  late Atom<int> _source;
  late Computed<int> _computed;

  @override
  void setup() {
    _ctx = ValenceContext();
    _source = Atom(0, context: _ctx);
    _computed = Computed(() => _source.value() * 2, context: _ctx);
  }

  @override
  void run() {
    for (var i = 0; i < 10000; i++) {
      _source.update((v) => v + 1, flush: true);
      _computed.value();
    }
  }

  @override
  void teardown() {
    _computed.dispose();
    _source.dispose();
  }
}

/// Benchmark: reading the tail of a 100-node computed chain.
class ComputedChainBenchmark extends BenchmarkBase {
  ComputedChainBenchmark() : super('Computed.Chain (100 deep, read tail)');

  late ValenceContext _ctx;
  late Atom<int> _source;
  late List<Computed<int>> _chain;

  @override
  void setup() {
    _ctx = ValenceContext();
    _source = Atom(1, context: _ctx);

    _chain = [];
    // Build a 100-node deep chain: each depends on the previous.
    Computed<int> prev = Computed(() => _source.value(), context: _ctx);
    _chain.add(prev);
    for (var i = 1; i < 100; i++) {
      final upstream = prev;
      final next = Computed(() => upstream.value() + 1, context: _ctx);
      _chain.add(next);
      prev = next;
    }
  }

  @override
  void run() {
    // Invalidate root and force full chain recomputation.
    _source.update((v) => v + 1, flush: true);
    _chain.last.value();
  }

  @override
  void teardown() {
    for (final c in _chain.reversed) {
      c.dispose();
    }
    _source.dispose();
  }
}

/// Benchmark: disposing 1,000 computed nodes.
class ComputedDisposeBenchmark extends BenchmarkBase {
  ComputedDisposeBenchmark() : super('Computed.Dispose (1,000 nodes)');

  late ValenceContext _ctx;
  late Atom<int> _source;
  late List<Computed<int>> _nodes;

  @override
  void setup() {
    _ctx = ValenceContext();
    _source = Atom(0, context: _ctx);
    _nodes = [
      for (var i = 0; i < 1000; i++)
        Computed(() => _source.value() + i, context: _ctx),
    ];
  }

  @override
  void run() {
    for (final c in _nodes) {
      c.dispose();
    }
    // Re-create for next iteration.
    _nodes = [
      for (var i = 0; i < 1000; i++)
        Computed(() => _source.value() + i, context: _ctx),
    ];
  }

  @override
  void teardown() {
    for (final c in _nodes) {
      c.dispose();
    }
    _source.dispose();
  }
}

void main() {
  print('=== Computed Benchmarks ===\n');

  ComputedCreationBenchmark().report();
  ComputedReadCleanBenchmark().report();
  ComputedRecomputeBenchmark().report();
  ComputedChainBenchmark().report();
  ComputedDisposeBenchmark().report();
}
