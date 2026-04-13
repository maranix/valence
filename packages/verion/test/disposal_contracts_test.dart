import 'package:test/test.dart';
import 'package:verion/verion.dart';

import 'utils.dart';

void main() {
  group('Disposal Contracts', () {
    test('disposed source throws on dispatch', () {
      final (src, setSrc) = createSource<int>(1);

      src.dispose();

      expect(
        () => setSrc(2),
        throwsA(isA<VerionDisposedNodeError>()),
      );
    });

    test('disposed derive throws on read', () {
      final (src, _) = createSource<int>(1);
      final derived = derive((sub) => sub(src));

      derived.dispose();

      expect(
        () => derived.value,
        throwsA(isA<VerionDisposedNodeError>()),
      );
    });

    test('double dispose throws VerionDisposedNodeError', () {
      final (src, _) = createSource<int>(1);

      src.dispose();

      expect(
        () => src.dispose(),
        throwsA(isA<VerionDisposedNodeError>()),
      );
    });

    test('trigger cleanup runs on derive disposed', () {
      // Create a scope to ensure we don't leak anything
      final scope = createScope();

      final (src, setSrc) = createSource<int>(1, label: 'src');
      final derived = derive((sub) => sub(src) * 2, label: 'derive');

      final sink = trigger((sub) {
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
      final (src, _) = createSource<int>(1);
      src.dispose();
      expect(
        () => src.addListener((_) {}),
        throwsA(isA<VerionDisposedNodeError>()),
      );
    });
  });
}
