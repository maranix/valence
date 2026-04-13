import 'package:flutter/material.dart';
import 'package:verion_flutter/src/provider.dart';
import 'package:verion_flutter/verion_flutter.dart';

enum CounterStoreEvent implements SourceEvent<int> {
  increment,
  decrement
  ;

  @override
  int reduce(int count) => switch (this) {
    .increment => count + 1,
    .decrement => count + 1,
  };
}

void main() {
  runApp(
    const CounterApp(),
  );
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VerionScopeProvider(
        scope: VerionScope(),
        child: const CounterPage(),
      ),
    );
  }
}

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final counterStore = VerionScopeProvider.of(
      context,
    ).source<int, CounterStoreEvent>(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Counter",
        ),
      ),
      body: Center(
        child: DeriveBuilder(
          derive: (sub) => sub(counterStore),
          builder: (count) => Text(
            '$count',
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
      ),
      floatingActionButton: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () => counterStore.dispatch(.increment),
          ),
          const SizedBox(height: 4),
          FloatingActionButton(
            child: const Icon(Icons.remove),
            onPressed: () => counterStore.dispatch(.decrement),
          ),
        ],
      ),
    );
  }
}
