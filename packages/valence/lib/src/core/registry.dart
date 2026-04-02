import 'package:valence/src/core/node/nodes.dart';

abstract interface class NodeRegistry {
  factory NodeRegistry() = _NodeRegistryImpl;

  int allocateId();

  void registerNode(Node node);

  void unregisterNode(Node node);

  T? resolveNode<T extends Node>(int id);

  T? resolveNodeMetadata<T extends NodeMetadata>(int nodeId);

  void linkSelector(SelectorNode selectorNode, SourceNode storeNode);

  List<T> resolveDependents<T extends Node>(Node node);

  void reconcileDependencies(int id, Set<int> deps);

  void dispose();
}

final class _NodeRegistryImpl implements NodeRegistry {
  bool _disposed = false;

  final List<int> _recycledIds = [];

  final List<Node?> _nodes = [];

  final Map<int, NodeMetadata> _nodeIdToMetadata = .new();

  /// Throws a StateError if the Registry is dead or dying.
  void _ensureAlive() {
    if (_disposed) {
      throw StateError(
        "Valence: Attempted to modify the NodeRegistry during or after it was disposed. "
        "Ensure all asynchronous operations are canceled when your Scope dies.",
      );
    }
  }

  @override
  int allocateId() {
    _ensureAlive();

    if (_recycledIds.isNotEmpty) {
      return _recycledIds.removeLast();
    }

    final id = _nodes.length;

    _nodes.add(null);

    return id;
  }

  @override
  void registerNode(Node node) {
    _ensureAlive();

    final id = node.id;
    _nodes[id] = node;

    _nodeIdToMetadata[id] = switch (node) {
      SourceNode _ => SourceNodeMetadata(),
      SelectorNode _ => SelectorNodeMetadata(node.storeId),
      RelayNode _ => RelayNodeMetadata(),
      ObserverNode _ => ObserverNodeMetadata(),
      _ => throw ArgumentError("Valence: Invalid Node type"),
    };
  }

  @override
  void unregisterNode(Node node) {
    if (_disposed) return;

    final id = node.id;
    final metadata = resolveNodeMetadata(node.id);

    if (metadata is ChildNodes) {
      for (final nodeId in metadata.children.toList()) {
        _nodes[nodeId]?.dispose();
      }
    }

    if (metadata is ParentNodes) {
      // Sever connection with parent nodes
      for (final parentId in metadata.parents) {
        resolveNodeMetadata<ChildNodes>(
          parentId,
        )?.children.remove(node.id);
      }
    } else if (metadata is SelectorNodeMetadata) {
      resolveNodeMetadata<ChildNodes>(
        metadata.sourceId,
      )?.children.remove(id);
    }

    _nodes[id] = null;
    _recycledIds.add(id);
    _nodeIdToMetadata.remove(id);
  }

  @override
  T? resolveNode<T extends Node>(int id) {
    if (id < 0 || id >= _nodes.length) return null;

    return _nodes[id] as T;
  }

  @override
  T? resolveNodeMetadata<T extends NodeMetadata>(int nodeId) {
    final meta = _nodeIdToMetadata[nodeId];
    if (meta == null) return null;

    if (meta is! T) {
      throw Exception(
        "Type mismatch during Metadata resolve: Got ${meta.runtimeType}\t Expected: ${T.runtimeType}",
      );
    }

    return meta;
  }

  @override
  void linkSelector(
    SelectorNode selectorNode,
    SourceNode storeNode,
  ) {
    _ensureAlive();

    resolveNodeMetadata<SourceNodeMetadata>(
      storeNode.id,
    )?.children.add(selectorNode.id);
  }

  @override
  List<T> resolveDependents<T extends Node>(Node node) {
    _ensureAlive();

    final metadata = resolveNodeMetadata<ChildNodes>(node.id);
    if (metadata == null) return [];

    return metadata.children
        .map((id) => _nodes[id])
        .nonNulls
        .cast<T>()
        .toList();
  }

  @override
  void reconcileDependencies(int id, Set<int> deps) {
    final metadata = resolveNodeMetadata<ParentNodes>(id);
    if (metadata == null) {
      throw StateError(
        "Valence: Attempted to reconcile dependencies for Node $id, "
        "but it does not have ParentNodes capabilities.",
      );
    }

    final oldDeps = metadata.parents;

    final removed = oldDeps.difference(deps);
    final added = deps.difference(oldDeps);

    // 1. Sever old edges
    for (final parentId in removed) {
      resolveNodeMetadata<ChildNodes>(parentId)?.children.remove(id);
    }

    // 2. Draw NEW edges (Only iterate over 'added'!)
    for (final parentId in added) {
      final parent = resolveNodeMetadata(parentId);
      if (parent is ChildNodes) {
        parent.children.add(id);
      }
    }

    // 3. Calculate Depth (Iterate over ALL 'deps')
    int maxParentDepth = -1;

    for (final parentId in deps) {
      final parent = resolveNodeMetadata(parentId);

      int currParentDepth = -1;
      if (parent is ParentNodes) {
        currParentDepth = parent.depth;
      } else if (parent is SelectorNodeMetadata) {
        currParentDepth = 0;
      }

      if (currParentDepth > maxParentDepth) {
        maxParentDepth = currParentDepth;
      }
    }
    metadata.depth = maxParentDepth + 1;
    metadata.parents
      ..clear()
      ..addAll(deps);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;

    for (final node in _nodes) {
      node?.dispose();
    }

    _nodes.clear();
    _recycledIds.clear();
    _nodeIdToMetadata.clear();
  }
}
