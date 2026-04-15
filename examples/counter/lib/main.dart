import 'package:flutter/material.dart';
import 'package:verion_flutter/verion_flutter.dart';

enum CounterSourceEvent implements SourceEvent<int> {
  increment,
  decrement;

  @override
  int reduce(int count) => switch (this) {
    .increment => count + 1,
    .decrement => count - 1,
  };
}

final class CounterScope extends VerionScope {
  CounterScope();

  late final count = source<int, CounterSourceEvent>(0);

  static CounterScope of(BuildContext context) =>
      VerionScopeProvider.of<CounterScope>(context);
}

final class Observer extends VerionObserver {
  @override
  void onScopeCreated(VerionScope scope) {
    print('onScopeCreated');
  }

  @override
  void onScopeDisposed(VerionScope scope) {
    print('onScopeDisposed');
  }

  @override
  void onSourceCreated(
    covariant Source<dynamic, SourceEvent<dynamic>> source,
    dynamic value,
  ) {
    print('onSourceCreated:${source.label}\t$value');
  }

  @override
  void onSourceUpdated(
    covariant Source<dynamic, SourceEvent<dynamic>> source,
    SourceEvent event,
    dynamic prevValue,
    dynamic nextValue,
  ) {
    print(
      'onSourceUpdated:${source.label}\tprev: $prevValue | next: $nextValue',
    );
  }

  @override
  void onSourceDiposed(covariant Source<dynamic, SourceEvent<dynamic>> source) {
    print('onSourceDisposed:${source.label}');
  }

  @override
  void onDeriveCreated(covariant Derive<dynamic> derive) {
    print('onDeriveCreated:${derive.label}');
  }

  @override
  void onDeriveSubscribed(
    covariant Derive<dynamic> derive,
    ReadableVerion node,
  ) {
    print('onDeriveSubscribed:${derive.label}');
  }

  @override
  void onDeriveUpdated(
    covariant Derive<dynamic> derive,
    dynamic prevValue,
    dynamic nextValue,
  ) {
    print('onDeriveUpdated:${derive.label}');
  }

  @override
  void onDeriveDisposed(covariant Derive<dynamic> derive) {
    print('onDeriveDisposed:${derive.label}');
  }
}

void main() {
  VerionObserver.instance = Observer();

  runApp(const CounterApp());
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VerionScopeProvider(scope: CounterScope(), child: CounterPage()),
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Counter")),
      body: Center(
        child: DeriveBuilder<int, CounterScope>(
          derive: (sub, scope) {
            return sub(scope.count);
          },
          builder: (count) =>
              Text('$count', style: Theme.of(context).textTheme.displayLarge),
        ),
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () =>
                CounterScope.of(context).count.dispatch(.increment),
          ),
          const SizedBox(height: 4),
          FloatingActionButton(
            child: const Icon(Icons.remove),
            onPressed: () =>
                CounterScope.of(context).count.dispatch(.decrement),
          ),
        ],
      ),
    );
  }
}
