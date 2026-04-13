import 'package:test/test.dart';
import 'package:verion/verion.dart';

import 'utils.dart';

void main() {
  group('Disposal Contracts', () {
    late VerionScope scope;

    setUp(() {
      scope = VerionScope(label: "Disposal Test");
    });

    tearDown(() {
      scope.dispose();
    });

    test('disposed source throws on dispatch', () {
      final (src, setSrc) = createSource<int>(scope, 1);

      src.dispose();

      expect(
        () => setSrc(2),
        throwsA(isA<VerionDisposedNodeError>()),
      );
    });

    test('disposed derive throws on read', () {
      final (src, _) = createSource<int>(scope, 1);
      final derived = scope.derive((sub) => sub(src));

      derived.dispose();

      expect(
        () => derived.value,
        throwsA(isA<VerionDisposedNodeError>()),
      );
    });

    test('double dispose throws VerionDisposedNodeError', () {
      final (src, _) = createSource<int>(scope, 1);

      src.dispose();

      expect(
        () => src.dispose(),
        throwsA(isA<VerionDisposedNodeError>()),
      );
    });

    test('trigger cleanup runs on derive disposed', () {
      // Create a scope to ensure we don't leak anything
      final scope = VerionScope();

      final (src, setSrc) = createSource<int>(scope, 1, label: 'src');
      final derived = scope.derive((sub) => sub(src) * 2, label: 'derive');

      final sink = scope.trigger((sub) {
        sub(derived);
      }, label: 'sink');

      sink.dispose();

      expect(sink.disposed, isTrue);

      // Cleanup
      derived.dispose();
      src.dispose();
      scope.dispose();
    });

    test('adding listener to disposed source throws', () {
      final (src, _) = createSource<int>(scope, 1);
      src.dispose();
      expect(
        () => src.addListener((_) {}),
        throwsA(isA<VerionDisposedNodeError>()),
      );
    });
  });
}
