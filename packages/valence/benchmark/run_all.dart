import 'atom_benchmark.dart' as atom;
import 'computed_benchmark.dart' as computed;
import 'effect_benchmark.dart' as effect;
import 'scheduler_benchmark.dart' as scheduler;
import 'graph_benchmark.dart' as graph;

void main() {
  print('╔══════════════════════════════════════════════════════╗');
  print('║          Valence Performance Benchmarks              ║');
  print('╚══════════════════════════════════════════════════════╝');
  print('');

  atom.main();
  print('');

  computed.main();
  print('');

  effect.main();
  print('');

  scheduler.main();
  print('');

  graph.main();
  print('');

  print('══════════════════════════════════════════════════════');
  print(' All benchmarks complete.');
  print('══════════════════════════════════════════════════════');
}
