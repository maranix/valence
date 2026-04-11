import 'package:meta/meta.dart';
import 'package:verion/src/constants.dart';
import 'package:verion/src/core/core.dart';
import 'package:verion/src/core/scope.dart';
import 'package:verion/src/types.dart';

abstract class VerionBase {
  VerionBase({Scope? scope, String? label})
    : _label = label,
      _scope = scope ?? globalScope {
    _scope.registerNode(this);
  }

  final String? _label;
  String get label => _label ?? runtimeType.toString();

  final Scope _scope;
  Scope get scope => _scope;

  @internal
  int get depth => 0;

  List<VerionBase>? _parents;
  List<VerionBase>? _children;

  @internal
  @protected
  bool get hasParents => _parents != null && _parents!.isNotEmpty;
  @internal
  @protected
  bool get hasChildren => _children != null && _children!.isNotEmpty;

  @internal
  @protected
  List<VerionBase> get parents => _parents!;
  @internal
  @protected
  List<VerionBase> get children => _children!;

  bool _disposed = false;
  bool get disposed => _disposed;

  bool dirty = false;

  @internal
  @protected
  void throwOnDisposed([String? action]) {
    if (!disposed) return;

    throw VerionDisposedNodeError(this, action);
  }

  @internal
  @mustBeOverridden
  void refresh();

  @mustCallSuper
  void dispose() {
    throwOnDisposed("dispose");

    _disposed = true;

    if (hasChildren) {
      while (children.isNotEmpty) {
        children.removeLast().dispose();
      }
      _children = null;
    }

    if (hasParents) {
      while (parents.isNotEmpty) {
        parents.removeLast().removeChild(this);
      }
      _parents = null;
    }

    _scope.removeNode(this);
  }

  @internal
  @protected
  void addChild(VerionBase node) {
    if (!hasChildren) _children = [];

    if (!children.contains(node)) {
      children.add(node);
    }
  }

  @internal
  @protected
  void addParent(VerionBase node) {
    if (!hasParents) _parents = [];

    if (!parents.contains(node)) {
      parents.add(node);

      node.addChild(this);

      onParentAdded(node);
    }
  }

  @internal
  @protected
  void removeChild(VerionBase node) {
    if (!hasChildren) return;

    final nodeIdx = children.indexOf(node);
    if (nodeIdx == -1) return;

    children[nodeIdx] = children.last;
    children.removeLast();
  }

  @internal
  @protected
  void removeParent(VerionBase node) {
    if (!hasParents) return;

    final nodeIdx = parents.indexOf(node);
    if (nodeIdx == -1) return;

    parents[nodeIdx] = parents.last;
    parents.removeLast();
  }

  @internal
  @protected
  void diffSubs(List<VerionBase> subs) {
    final oldSubs = _parents ?? [];

    bool subsChanged = oldSubs.length != subs.length;

    // Fast path
    if (!subsChanged) {
      // If the length of previous and current subscriptions is equals
      // check whether any of the subscriptions are different
      for (var i = oldSubs.length - 1; i >= 0; i--) {
        // Order will relatively stay the same,
        //
        // I don't see any cases where subscriptions will only change their order
        if (oldSubs[i] != subs[i]) {
          subsChanged = true;
          break;
        }
      }
    }

    // If subscriptions still did not change, return
    // This node is currently stable
    if (!subsChanged) {
      return;
    }

    // Slow path: recompute subscriptions array
    final oldSet = oldSubs.toSet();
    final newSet = subs.toSet();

    // removed subscriptions
    for (final node in oldSet.difference(newSet)) {
      node.removeChild(this);
    }

    // new subscriptions
    for (final node in newSet.difference(oldSet)) {
      node.addChild(this);

      onParentAdded(node);
    }

    // Save a copy of this, since [subs] array is cleared
    _parents = subs.toList();
  }

  @internal
  @protected
  void onParentAdded(VerionBase node);

  @internal
  @protected
  void cascadeParentDepthToChildren(int newDepth);
}

abstract class ReadableVerion<T> extends VerionBase {
  ReadableVerion({super.scope, super.label});

  T get value;
}

mixin ListenableVerion<T> on ReadableVerion<T> {
  final List<ValueCallback<T>> _listeners = [];

  void addListener(ValueCallback<T> fn) {
    throwOnDisposed("attach listener to");

    _listeners.add(fn);
  }

  void removeListener(ValueCallback<T> fn) => _listeners.remove(fn);

  void notifyListeners() {
    for (var i = 0; i < _listeners.length; i++) {
      _listeners[i](value);
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    _listeners.clear();

    super.dispose();
  }
}

mixin DependentVerion on VerionBase {
  int _depth = 1;

  @override
  int get depth => _depth;

  @internal
  @protected
  @override
  void onParentAdded(VerionBase node) {
    cascadeParentDepthToChildren(node.depth);
  }

  @override
  void cascadeParentDepthToChildren(int newDepth) {
    // Child nodes should be strictly in a deeper depth than the parent
    if (_depth > newDepth) return;

    _depth = newDepth + 1;

    if (hasChildren) {
      for (final child in children) {
        child.cascadeParentDepthToChildren(_depth);
      }
    }
  }
}
