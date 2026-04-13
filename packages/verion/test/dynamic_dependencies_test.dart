import 'package:test/test.dart';
import 'package:verion/verion.dart';

import 'utils.dart';

void main() {
  group('Dynamic Dependencies', () {
    test('derive tracks new dependency when fn changes branch', () async {
      final (flag, setFlag) = createSource<bool>(true);
      final (a, setA) = createSource<int>(1);
      final (b, setB) = createSource<int>(2);

      final result = derive((sub) => sub(flag) ? sub(a) : sub(b));

      int? observeValue;
      int observeEvals = 0;
      final sink = trigger((sub) {
        observeValue = sub(result);
        observeEvals++;
      });
      await pump();

      expect(observeValue, 1);
      expect(observeEvals, 1);

      // Initially, it shouldn't react to `b` changing because it only reads `a`
      setB(3);
      await pump();

      expect(observeEvals, 1);

      // Update `a`, it should react
      setA(5);
      await pump();

      expect(observeValue, 5);
      expect(observeEvals, 2);

      // Flip the flag, it should now read `b` and stop reacting to `a`
      setFlag(false);
      await pump();

      expect(observeValue, 3); // latest value of b is 3
      expect(observeEvals, 3);

      // Update `a` again, it should NOT react anymore
      setA(10);
      await pump();

      expect(observeEvals, 3); // Still 3

      // Update `b`, it should react
      setB(4);
      await pump();

      expect(observeValue, 4);
      expect(observeEvals, 4);

      sink.dispose();
    });

    test('derive drops old dependency after branch change', () async {
      final (flag, setFlag) = createSource<bool>(true);
      final (a, setA) = createSource<int>(1);

      final result = derive((sub) => sub(flag) ? sub(a) : 0);

      int observeEvals = 0;
      final sink = trigger((sub) {
        sub(result);
        observeEvals++;
      });
      await pump();

      expect(observeEvals, 1);

      // Initially reacts to `a`
      setA(2);
      await pump();

      expect(observeEvals, 2);

      // Switch branch to not use `a`
      setFlag(false);
      await pump();

      expect(observeEvals, 3);

      // Update `a`, it should no longer cause evaluation
      setA(3);
      await pump();

      expect(observeEvals, 3);

      sink.dispose();
    });
  });
}
