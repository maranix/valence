import 'package:valence/src/core/scope.dart';

final Scope rootScope = Scope();

abstract final class Valence {
  void disposeRootScope() => rootScope.dispose();
}
