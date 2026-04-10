import 'package:verion/src/core/base.dart';
import 'package:verion/src/core/derive.dart';
import 'package:verion/src/core/scope.dart';
import 'package:verion/src/core/source.dart';

abstract base class VerionObserver {
  void onScopeCreated(VerionScope scope);
  void onScopeDisposed(VerionScope scope);

  void onSourceCreated(SourceBase source, dynamic value);
  void onSourceUpdated(
    SourceBase source,
    SourceEvent event,
    dynamic prevValue,
    dynamic nextValue,
  );
  void onSourceDiposed(SourceBase source);

  void onDeriveCreated(DeriveBase derive);
  void onDeriveSubscribed(DeriveBase derive, ReadableVerion node);
  void onDeriveUpdated(DeriveBase derive, dynamic prevValue, dynamic nextValue);
  void onDeriveDisposed(DeriveBase derive);

  static VerionObserver? instance;
}
