import 'package:collection/collection.dart';
import 'package:valence/src/engine/node.dart';

abstract interface class Registry {
  factory Registry() = _RegistryImpl;

  /// Registers a [Source] for disposal when this scope is disposed.
  void registerSource(Source source);

  /// Registers a [Dependent] for disposal when this scope is disposed.
  ///
  /// Dependents are disposed before sources, and deepest-first among
  /// themselves.
  ///
  /// Ensuring no [Dependent] fires into an already-disposed node.
  void registerDependent(Dependent dependent);

  void dispose();
}

final class _RegistryImpl implements Registry {
  final List<Source> _sources = [];
  final PriorityQueue<Dependent> _dependents = PriorityQueue(
    (a, b) => b.depth.compareTo(a.depth),
  );

  @override
  void registerSource(Source source) => _sources.add(source);

  @override
  void registerDependent(Dependent dependent) => _dependents.add(dependent);

  @override
  void dispose() {
    while (_dependents.isNotEmpty) {
      _dependents.removeFirst().dispose();
    }

    for (final s in _sources) {
      s.dispose();
    }

    _sources.clear();
    _dependents.clear();
  }
}
