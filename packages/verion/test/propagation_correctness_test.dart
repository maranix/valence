import 'package:test/test.dart';
import 'package:verion/verion.dart';

import 'utils.dart';

void main() {
  group('Propagation Correctness', () {
    late VerionScope scope;

    setUp(() {
      scope = VerionScope(label: "Propagation Correctness Test");
    });

    tearDown(() {
      scope.dispose();
    });

    test('source -> scope.derive -> scope.trigger propagates value', () async {
      final (src, setSrc) = createSource<int>(scope, 1);
      final derived = scope.derive((sub) => sub(src) * 2);

      int? observeValue;
      final sink = scope.trigger((sub) {
        observeValue = sub(derived);
      });
      await pump();

      expect(observeValue, 2);

      setSrc(5);
      await pump();

      expect(observeValue, 10);

      sink.dispose();
    });

    test(
      'scope.derive equality-gates: does not propagate when output unchanged',
      () async {
        final (src, setSrc) = createSource<int>(scope, 1);

        int deriveEvals = 0;
        final isEven = scope.derive((sub) {
          deriveEvals++;
          return sub(src) % 2 == 0;
        });

        int observeEvals = 0;
        final sink = scope.trigger((sub) {
          observeEvals++;
          sub(isEven);
        });
        await pump();

        expect(deriveEvals, 1);
        expect(observeEvals, 1);

        // Update with an odd number, output is still `false` (1 % 2 == 0 is false, 3 % 2 == 0 is false)
        setSrc(3);
        await pump();

        expect(deriveEvals, 2); // Derive re-evaluates because source changed
        expect(
          observeEvals,
          1,
        ); // Sink does NOT re-evaluate because derived output remained strictly equals

        // Update with an even number
        setSrc(4);
        await pump();

        expect(deriveEvals, 3);
        expect(
          observeEvals,
          2,
        ); // Sink evaluates because derived output changed to `true`

        sink.dispose();
      },
    );

    test('scope.derive is lazy: not computed until first read', () {
      final (src, _) = createSource<int>(scope, 1);

      int evalCount = 0;
      final lazyDerive = scope.derive((sub) {
        evalCount++;
        return sub(src);
      });

      expect(evalCount, 0); // Not read yet
      expect(lazyDerive.value, 1);
      expect(evalCount, 1);
    });

    test('unread scope.derive skips refresh entirely', () async {
      final (src, setSrc) = createSource<int>(scope, 1);

      int evalCount = 0;
      final unreadDerive = scope.derive((sub) {
        evalCount++;
        return sub(src);
      });

      setSrc(2);
      setSrc(3);
      await pump();

      expect(evalCount, 0); // Still 0

      // Now read it
      expect(unreadDerive.value, 3);
      expect(evalCount, 1);
    });

    test('source equality-gates: dispatch with same value is no-op', () async {
      final (src, setSrc) = createSource<int>(scope, 1);

      int evalCount = 0;
      final sink = scope.trigger((sub) {
        evalCount++;
        sub(src);
      });
      await pump();

      expect(evalCount, 1);

      setSrc(1); // Same value
      await pump();

      expect(evalCount, 1);

      setSrc(2); // Diff value
      await pump();

      expect(evalCount, 2);

      sink.dispose();
    });

    test('listener fires post-flush with correct value', () async {
      final (src, setSrc) = createSource<int>(scope, 1);
      final derived = scope.derive((sub) => sub(src) * 2);

      // Bind the derived to the source by reading it once
      // otherwise it has no children in the graph and skip schedules
      expect(derived.value, 2);

      int? innerVal;
      derived.addListener((val) {
        innerVal = val;
      });

      setSrc(2);
      await pump();

      // listener was called
      expect(innerVal, 4);
    });
  });
}
