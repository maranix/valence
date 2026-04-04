import 'package:valence/src/core/scope.dart';

final Scope rootScope = Scope();

abstract final class Valence {
  static void disposeRootScope() => rootScope.dispose();

  static int maxCircularDepedencyIteration = 100_000;
}
