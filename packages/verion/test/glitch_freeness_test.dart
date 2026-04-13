import 'package:test/test.dart';
import 'package:verion/verion.dart';

import 'utils.dart';

void main() {
  group('Glitch-Freeness (Topology Tests)', () {
    late VerionScope scope;

    setUp(() {
      scope = VerionScope(label: "Glitch-Freeness Test");
    });

    tearDown(() {
      scope.dispose();
    });

    test('diamond dependency - no glitch', () async {
      final (a, setA) = createSource<int>(scope, 1, label: 'a');

      final b = scope.derive<int>((sub) => sub(a) * 2, label: 'b');
      final c = scope.derive<int>((sub) => sub(a) * 3, label: 'c');

      final dValues = <int>[];
      final d = scope.derive<int>((sub) => sub(b) + sub(c), label: 'd');

      final sub = scope.trigger((sub) {
        dValues.add(sub(d));
      });
      await pump();

      // Initial read
      expect(dValues, [5]); // 1*2 + 1*3

      // Update A to 2
      // If it glitches, D might see B=4 and C=3 (7) or B=2 and C=6 (8)
      // D should strictly only see B=4 and C=6 (10)
      setA(2);
      await pump();

      expect(dValues, [5, 10]);

      sub.dispose();
    });

    test('fan-out topology - no glitch', () async {
      final (src, setSrc) = createSource<int>(scope, 10);

      final derived1 = scope.derive<int>((sub) => sub(src) + 1);
      final derived2 = scope.derive<int>((sub) => sub(src) + 2);
      final derived3 = scope.derive<int>((sub) => sub(src) + 3);

      final sinkValues = <int>[];
      final sink = scope.trigger((sub) {
        // Force type resolution by mapping and reducing
        final val1 = sub(derived1);
        final val2 = sub(derived2);
        final val3 = sub(derived3);
        sinkValues.add(val1 + val2 + val3);
      });
      await pump();

      expect(sinkValues, [36]); // 11 + 12 + 13

      setSrc(20);
      await pump();

      expect(sinkValues, [36, 66]); // 21 + 22 + 23 = 66

      sink.dispose();
    });

    test('long chain - propagates correctly without glitching', () async {
      final (a, setA) = createSource<int>(scope, 1);

      final b = scope.derive<int>((sub) => sub(a) + 1);
      final c = scope.derive<int>((sub) => sub(b) + 1);
      final d = scope.derive<int>((sub) => sub(c) + 1);
      final e = scope.derive<int>((sub) => sub(d) + 1);

      final values = <int>[];
      final sink = scope.trigger((sub) {
        values.add(sub(e)); // e should be a + 4
      });
      await pump();

      expect(values, [5]);

      setA(10);
      await pump();

      expect(values, [5, 14]);

      sink.dispose();
    });

    test('multi-source merge - single flush using scope.batch', () async {
      final (a, setA) = createSource<int>(scope, 1);
      final (b, setB) = createSource<int>(scope, 10);
      final (c, setC) = createSource<int>(scope, 100);

      final sum = scope.derive<int>((sub) {
        final va = sub(a);
        final vb = sub(b);
        final vc = sub(c);
        return va + vb + vc;
      });

      final values = <int>[];
      final sink = scope.trigger((sub) {
        values.add(sub(sum));
      });
      await pump();

      expect(values, [111]);

      scope.batch(() {
        setA(2);
        setB(20);
        setC(200);
      });
      await pump();

      // Instead of 3 evaluations, it should be precisely 1 evaluation containing all updates.
      expect(values, [111, 222]);

      sink.dispose();
    });
  });
}
