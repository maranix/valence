import 'package:flutter/widgets.dart';

import 'package:verion/verion.dart';

class SourceBuilder<T, E extends SourceEvent<T>> extends StatefulWidget {
  const SourceBuilder({
    super.key,
    required this.source,
    required this.builder,
  });

  final Source<T, E> source;
  final Widget Function(T) builder;

  @override
  State<SourceBuilder<T, E>> createState() => _SourceBuilderState<T, E>();
}

class _SourceBuilderState<T, E extends SourceEvent<T>>
    extends State<SourceBuilder<T, E>> {
  late T _value;

  void _onChangeListener(T val) {
    setState(() {
      _value = val;
    });
  }

  @override
  void initState() {
    super.initState();

    _value = widget.source.value;
    widget.source.addListener(_onChangeListener);
  }

  @override
  void didUpdateWidget(covariant SourceBuilder<T, E> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.source != widget.source) {
      oldWidget.source.removeListener(_onChangeListener);
      _value = widget.source.value;
      widget.source.addListener(_onChangeListener);
    }
  }

  @override
  void dispose() {
    widget.source.removeListener(_onChangeListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_value);
  }
}
