part of 'nodes.dart';

// TODO: Cleanup messy mixins to avoid [is] checks in Registry.

/// Mixin to track dependent [child] nodes.
mixin ChildNodes on NodeMetadata {
  /// The set of IDs of nodes that depend on this node.
  final Set<int> children = <int>{};
}

/// Mixin to track dependencies [Parent] nodes.
///
/// Nodes that have parents are dependents hence they are bound to have depth property.
mixin ParentNodes on NodeMetadata {
  /// The set of IDs of nodes this node depends on.
  final Set<int> parents = <int>{};

  int _depth = -1;

  /// The current depth of the node.
  int get depth => _depth;

  set depth(int d) {
    if (d <= 0) {
      throw RangeError.value(
        d,
        "depth",
        "Invalid topological sort: A consumer node's depth must be >= 1.",
      );
    }

    _depth = d;
  }
}

/// Mixin for nodes that can be marked as dirty.
mixin NodeDirtyState on NodeMetadata {
  bool _dirty = false;

  /// Whether the node is marked as dirty.
  bool get dirty => _dirty;

  /// Marks the node as dirty.
  void markDirty() {
    _dirty = true;
  }

  /// Unmarks the node as dirty.
  void unmarkDirty() {
    _dirty = false;
  }
}

/// Base class for all node metadata.
///
/// Subclasses define specific properties and behaviors for different node types.
sealed class NodeMetadata {}

/// Metadata for source nodes.
final class SourceNodeMetadata extends NodeMetadata with ChildNodes {}

/// Metadata for selector nodes.
final class SelectorNodeMetadata extends NodeMetadata with ChildNodes {
  SelectorNodeMetadata(this.sourceId);

  final int sourceId;
}

/// Metadata for relay nodes.
final class RelayNodeMetadata extends NodeMetadata
    with ParentNodes, ChildNodes {}

/// Metadata for observer nodes.
final class ObserverNodeMetadata extends NodeMetadata with ParentNodes {}
