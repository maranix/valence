import 'package:valence/src/engine/graph.dart';
import 'package:valence/src/engine/registry.dart';
import 'package:valence/src/engine/schedular.dart';

abstract interface class Scope {
  factory Scope() = _ScopeImpl;

  Graph get graph;
  Schedular get schedular;
  Registry get registry;

  void dispose();
}

final class _ScopeImpl implements Scope {
  _ScopeImpl({Graph? graph, Schedular? schedular})
    : _graph = graph ?? Graph(),
      _schedular = schedular ?? Schedular(),
      _registry = Registry();

  final Graph _graph;
  final Schedular _schedular;
  final Registry _registry;

  @override
  Graph get graph => _graph;

  @override
  Schedular get schedular => _schedular;

  @override
  Registry get registry => _registry;

  @override
  void dispose() => _registry.dispose();
}
