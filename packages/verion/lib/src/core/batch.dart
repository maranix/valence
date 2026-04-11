import 'package:verion/src/constants.dart';
import 'package:verion/src/core/scope.dart';
import 'package:verion/src/types.dart';

void batch(VoidCallback fn, {Scope? scope}) {
  (scope ?? globalScope).scheduler.batch(fn);
}
