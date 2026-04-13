import 'package:flutter/widgets.dart';
import 'package:verion/verion.dart';
import 'package:verion_flutter/src/provider.dart';

class DeriveBuilder<T> extends StatefulWidget {
  const DeriveBuilder({
    super.key,
    required this.derive,
    required this.builder,
    this.sourceLabel,
  });

  final T Function(SubscribeCallback) derive;
  final Widget Function(T) builder;
  final String? sourceLabel;

  @override
  State<DeriveBuilder<T>> createState() => _DeriveBuilderState<T>();
}

class _DeriveBuilderState<T> extends State<DeriveBuilder<T>> {
  late T _value;
  late final Derive<T> _derive;
  late final VerionScope _scope;

  void _onChangeListener(T value) {
    setState(() {
      _value = value;
    });
  }

  @override
  void initState() {
    super.initState();
    _scope = VerionScopeProvider.of(context, label: widget.sourceLabel);

    _derive = _scope.derive(widget.derive);
    _derive.addListener(_onChangeListener);

    _value = _derive.value;
  }

  @override
  void dispose() {
    _derive.removeListener(_onChangeListener);
    _derive.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_value);
  }
}
