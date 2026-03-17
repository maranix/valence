import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:valence/valence.dart';

/// Benchmark: creating 1,000 atoms.
class AtomCreationBenchmark extends BenchmarkBase {
  AtomCreationBenchmark() : super('Atom.Creation (1000 atoms)');

  late ValenceContext _ctx;

  @override
  void setup() {
    _ctx = ValenceContext();
  }

  @override
  void run() {
    final atoms = <Atom<int>>[];
    for (var i = 0; i < 1000; i++) {
      atoms.add(Atom(i, context: _ctx));
    }
    // Dispose to prevent accumulation across iterations.
    for (final a in atoms) {
      a.dispose();
    }
  }
}

/// Benchmark: reading an atom's value 10,000 times (no tracking scope).
class AtomReadBenchmark extends BenchmarkBase {
  AtomReadBenchmark() : super('Atom.Read (10,000 reads)');

  late ValenceContext _ctx;
  late Atom<int> _atom;

  @override
  void setup() {
    _ctx = ValenceContext();
    _atom = Atom(42, context: _ctx);
  }

  @override
  void run() {
    for (var i = 0; i < 10000; i++) {
      _atom.value();
    }
  }

  @override
  void teardown() {
    _atom.dispose();
  }
}

/// Benchmark: peeking an atom's value 10,000 times.
class AtomPeekBenchmark extends BenchmarkBase {
  AtomPeekBenchmark() : super('Atom.Peek (10,000 peeks)');

  late ValenceContext _ctx;
  late Atom<int> _atom;

  @override
  void setup() {
    _ctx = ValenceContext();
    _atom = Atom(42, context: _ctx);
  }

  @override
  void run() {
    for (var i = 0; i < 10000; i++) {
      _atom.peek();
    }
  }

  @override
  void teardown() {
    _atom.dispose();
  }
}

/// Benchmark: updating an atom 10,000 times (no dependents).
class AtomUpdateBenchmark extends BenchmarkBase {
  AtomUpdateBenchmark() : super('Atom.Update (10,000 updates, no deps)');

  late ValenceContext _ctx;
  late Atom<int> _atom;

  @override
  void setup() {
    _ctx = ValenceContext();
    _atom = Atom(0, context: _ctx);
  }

  @override
  void run() {
    for (var i = 0; i < 10000; i++) {
      _atom.update((v) => v + 1);
    }
  }

  @override
  void teardown() {
    _atom.dispose();
  }
}

/// Benchmark: updating an atom 10,000 times with flush: true (no dependents).
class AtomUpdateWithFlushBenchmark extends BenchmarkBase {
  AtomUpdateWithFlushBenchmark()
    : super('Atom.UpdateFlush (10,000 updates+flush)');

  late ValenceContext _ctx;
  late Atom<int> _atom;

  @override
  void setup() {
    _ctx = ValenceContext();
    _atom = Atom(0, context: _ctx);
  }

  @override
  void run() {
    for (var i = 0; i < 10000; i++) {
      _atom.update((v) => v + 1, flush: true);
    }
  }

  @override
  void teardown() {
    _atom.dispose();
  }
}

/// Benchmark: disposing 1,000 atoms.
class AtomDisposeBenchmark extends BenchmarkBase {
  AtomDisposeBenchmark() : super('Atom.Dispose (1,000 atoms)');

  late ValenceContext _ctx;
  late List<Atom<int>> _atoms;

  @override
  void setup() {
    _ctx = ValenceContext();
    _atoms = [for (var i = 0; i < 1000; i++) Atom(i, context: _ctx)];
  }

  @override
  void run() {
    for (final a in _atoms) {
      a.dispose();
    }
    // Re-create for the next iteration.
    _atoms = [for (var i = 0; i < 1000; i++) Atom(i, context: _ctx)];
  }

  @override
  void teardown() {
    for (final a in _atoms) {
      a.dispose();
    }
  }
}

void main() {
  print('=== Atom Benchmarks ===\n');

  AtomCreationBenchmark().report();
  AtomReadBenchmark().report();
  AtomPeekBenchmark().report();
  AtomUpdateBenchmark().report();
  AtomUpdateWithFlushBenchmark().report();
  AtomDisposeBenchmark().report();
}
