library;

export 'src/core/source.dart' show Source, SourceEvent;
export 'src/core/derive.dart' show Derive;
export 'src/core/trigger.dart' show Trigger;
export 'src/core/scope.dart' show VerionScope;

export 'src/extension/scope_extension.dart';

export 'src/types.dart';
export 'src/observer.dart';

export 'src/core/base.dart' show ReadableVerion;

export 'src/core/core.dart'
    show
        VerionError,
        VerionDisposedNodeError,
        VerionCircularDependencyDetected,
        VerionUnsupportedOperationError;
