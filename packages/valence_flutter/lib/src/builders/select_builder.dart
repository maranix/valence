import 'package:flutter/widgets.dart';
import 'package:valence/valence.dart';

class SelectBuilder<T> extends StatefulWidget {
  const SelectBuilder({
    super.key,
    required this.select,
    required this.builder,
  });

  final Select<T> select;
  final Widget Function(T) builder;

  @override
  State<SelectBuilder<T>> createState() => _SelectBuilderState<T>();
}

class _SelectBuilderState<T> extends State<SelectBuilder<T>> {
  late T _value;

  void _onChangeListener(T value) {
    setState(() {
      _value = value;
    });
  }

  @override
  void initState() {
    super.initState();

    _value = widget.select();
    widget.select.addListener(_onChangeListener);
  }

  @override
  void dispose() {
    widget.select.removeListener(_onChangeListener);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_value);
  }
}
