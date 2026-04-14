import 'package:flutter/widgets.dart';
import 'package:verion_flutter/verion_flutter.dart';

class VerionScopeProvider<T extends VerionScope> extends StatelessWidget {
  const VerionScopeProvider({
    super.key,
    required this.scope,
    required this.child,
    this.autoDispose = true,
  });

  final T scope;
  final Widget child;
  final bool autoDispose;

  static T? maybeOf<T extends VerionScope>(
    BuildContext context, {
    String? label,
  }) {
    if (label == null) {
      return _Provider.maybeOf<T>(context);
    }

    return _traverseWidgetTree(context, label: label);
  }

  static T of<T extends VerionScope>(
    BuildContext context, {
    String? label,
  }) {
    final injectedScope = VerionProvider.of<T>(context);
    if (label == null) {
      return injectedScope;
    } else if (injectedScope.label == label) {
      return injectedScope;
    }

    final scope = _traverseWidgetTree<T>(context, label: label);
    if (scope != null) {
      return scope;
    }

    throw StateError(
      'VerionScopeProvider with $label not found in the widget tree. '
      'Ensure you have VerionScope with $label as your parent in the widget tree.',
    );
  }

  /// Slow path
  /// Traverse the Widget Tree upwards and look for [VerionScope] with [label]
  static T? _traverseWidgetTree<T extends VerionScope>(
    BuildContext context, {
    String? label,
  }) {
    T? scope;

    context.visitAncestorElements((e) {
      if (e is _Provider<T>) {
        final el = e as _Provider<T>;

        if (el.value.label == label) {
          scope = el.value;
          return false;
        }
      }

      return true;
    });

    return scope;
  }

  @override
  Widget build(BuildContext context) {
    void Function(T)? dispose = switch (autoDispose) {
      true => (s) => s.dispose(),
      false => null,
    };

    return VerionProvider<T>(
      create: (context) => scope,
      onDispose: dispose,
      child: child,
    );
  }
}

final class VerionProvider<T> extends StatefulWidget {
  const VerionProvider({
    super.key,
    this.onDispose,
    required this.create,
    required this.child,
  });

  final T Function(BuildContext) create;
  final void Function(T)? onDispose;
  final Widget child;

  static T? maybeOf<T>(BuildContext context) => _Provider.maybeOf<T>(context);

  static T of<T>(BuildContext context) {
    final inheritedVal = maybeOf<T>(context);

    if (inheritedVal == null) {
      throw StateError(
        'VerionProvider<$T> not found in the widget tree. '
        'Ensure you have wrapped your widget tree with a VerionProvider<$T>.',
      );
    }

    return inheritedVal;
  }

  @override
  State<VerionProvider<T>> createState() => _VerionProviderState<T>();
}

class _VerionProviderState<T> extends State<VerionProvider<T>> {
  late final T _value;

  @override
  void initState() {
    super.initState();

    _value = widget.create(context);
  }

  @override
  void dispose() {
    if (widget.onDispose != null) {
      widget.onDispose!(_value);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Provider(
    value: _value,
    child: widget.child,
  );
}

final class _Provider<T> extends InheritedWidget {
  const _Provider({
    required this.value,
    required super.child,
    super.key,
  });

  final T value;

  static T? maybeOf<T>(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<_Provider<T>>();
    return (element?.widget as _Provider<T>?)?.value;
  }

  @override
  bool updateShouldNotify(covariant _Provider<T> oldWidget) =>
      oldWidget.value != value;
}
