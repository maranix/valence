import 'package:verion/src/core/base.dart';

sealed class VerionError extends Error {
  VerionError(this.message);

  final String message;

  @override
  String toString() => message;
}

final class VerionCircularDependencyDetected extends VerionError {
  VerionCircularDependencyDetected(this.node)
    : super(
        'Circular dependency detected. Node "${node.label}" is part of a dependency cycle.',
      );

  final VerionBase node;
}

final class VerionDisposedNodeError extends VerionError {
  VerionDisposedNodeError(this.node, [String? action])
    : super(
        '${node.label}: Cannot $action a disposed node.',
      );

  final VerionBase node;
}

final class VerionUnsupportedOperationError extends VerionError {
  VerionUnsupportedOperationError(this.node, String operation)
    : super(
        '${node.label}: The operation "$operation" is not supported on this node.',
      );

  final VerionBase node;
}
