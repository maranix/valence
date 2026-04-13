import 'package:test/test.dart';
import 'package:verion/verion.dart';

import 'utils.dart';

void main() {
  group('Batch Semantics', () {
    late VerionScope scope;

    setUp(() {
      scope = VerionScope(label: "Batch Test");
    });

    tearDown(() {
      scope.dispose();
    });

    test('batch: multiple dispatches, single flush', () async {
      final (a, setA) = createSource<int>(scope, 1);
      final (b, setB) = createSource<int>(scope, 2);

      final sum = scope.derive((sub) => sub(a) + sub(b));

      int observeEvals = 0;
      final sink = scope.trigger((sub) {
        sub(sum);
        observeEvals++;
      });
      await pump();

      expect(observeEvals, 1);

      scope.batch(() {
        setA(10);
        setB(20);
      });
      await pump();

      // Eval count strictly increments by 1
      expect(observeEvals, 2);

      sink.dispose();
    });

    test('batch: nested batches only flush on outermost exit', () async {
      final (a, setA) = createSource<int>(scope, 1);
      final (b, setB) = createSource<int>(scope, 2);
      final (c, setC) = createSource<int>(scope, 3);

      final sum = scope.derive((sub) => sub(a) + sub(b) + sub(c));

      int observeEvals = 0;
      final sink = scope.trigger((sub) {
        sub(sum);
        observeEvals++;
      });
      await pump();

      expect(observeEvals, 1);

      scope.batch(() {
        // Outer batch
        setA(10);

        scope.batch(() {
          // Inner batch 1
          setB(20);

          scope.batch(() {
            // Inner batch 2
            setC(30);
          });

          // Still no flush after inner batch 2 (even if we pumped, it wouldn't flush because batchDepth > 0)
        });
      });
      await pump();

      // Exactly 1 flush after outermost exit
      expect(observeEvals, 2);

      sink.dispose();
    });
  });
}
