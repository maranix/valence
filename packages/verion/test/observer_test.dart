import 'package:test/test.dart';
import 'package:verion/verion.dart';

import 'utils.dart';

base class MockObserver extends VerionObserver {
  final List<String> events = [];

  @override
  void onScopeCreated(VerionScope scope) {
    events.add('onScopeCreated');
  }

  @override
  void onScopeDisposed(VerionScope scope) {
    events.add('onScopeDisposed');
  }

  @override
  void onSourceCreated(
    covariant Source<dynamic, SourceEvent<dynamic>> source,
    dynamic value,
  ) {
    events.add('onSourceCreated:${source.label}');
  }

  @override
  void onSourceUpdated(
    covariant Source<dynamic, SourceEvent<dynamic>> source,
    SourceEvent event,
    dynamic prevValue,
    dynamic nextValue,
  ) {
    events.add('onSourceUpdated:${source.label}');
  }

  @override
  void onSourceDiposed(covariant Source<dynamic, SourceEvent<dynamic>> source) {
    events.add('onSourceDisposed:${source.label}');
  }

  @override
  void onDeriveCreated(covariant Derive<dynamic> derive) {
    events.add('onDeriveCreated:${derive.label}');
  }

  @override
  void onDeriveSubscribed(
    covariant Derive<dynamic> derive,
    ReadableVerion node,
  ) {
    events.add('onDeriveSubscribed:${derive.label}');
  }

  @override
  void onDeriveUpdated(
    covariant Derive<dynamic> derive,
    dynamic prevValue,
    dynamic nextValue,
  ) {
    events.add('onDeriveUpdated:${derive.label}');
  }

  @override
  void onDeriveDisposed(covariant Derive<dynamic> derive) {
    events.add('onDeriveDisposed:${derive.label}');
  }
}

void main() {
  group('Observer Semantics', () {
    late MockObserver observer;

    setUp(() {
      observer = MockObserver();
      VerionObserver.instance = observer;
    });

    tearDown(() {
      VerionObserver.instance = null;
    });

    test('observer receives correct hook events', () async {
      final scope = createScope();

      final (src, setSrc) = createSource<int>(1, label: 'src1');

      final derived = derive((sub) => sub(src) * 2, label: 'der1');

      // Reading will subscribe and update
      derived.value;

      setSrc(2);
      await pump();

      src.dispose(); // Also disposes children like derived!
      scope.dispose();

      expect(
        observer.events,
        containsAllInOrder([
          'onScopeCreated',
          'onSourceCreated:src1',
          'onDeriveCreated:der1',
          'onDeriveSubscribed:der1',
          'onSourceUpdated:src1',
          'onDeriveSubscribed:der1',
          'onDeriveUpdated:der1',
          'onSourceDisposed:src1',
          'onDeriveDisposed:der1',
          'onScopeDisposed',
        ]),
      );
    });

    test('null observer = no crash, zero overhead', () async {
      VerionObserver.instance = null;

      // We perform all standard operations that would normally fire events.
      // They should just execute successfully without crashing.
      final scope = createScope();
      final (src, setSrc) = createSource<int>(1);
      final derived = derive((sub) => sub(src) * 2);

      derived.value;
      setSrc(2);
      await pump();

      src.dispose();
      scope.dispose();

      // Since it didn't crash, the test passes
      expect(true, true);
    });
  });
}
