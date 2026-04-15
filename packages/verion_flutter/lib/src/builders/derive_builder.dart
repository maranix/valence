import 'package:flutter/widgets.dart';
import 'package:verion/verion.dart';
import 'package:verion_flutter/src/provider.dart';

// TODO: Improve the UX and purpose of this widget
//
//       This widget is currently really in a grey area and the usage is not quite clear as of now.
class DeriveBuilder<T, S extends VerionScope> extends StatefulWidget {
  const DeriveBuilder({
    super.key,
    required this.derive,
    required this.builder,
  });

  final T Function(SubscribeContext, S) derive;
  final Widget Function(T) builder;

  @override
  State<DeriveBuilder<T, S>> createState() => _DeriveBuilderState<T, S>();
}

class _DeriveBuilderState<T, S extends VerionScope>
    extends State<DeriveBuilder<T, S>> {
  late T _value;
  late final Derive<T> _derive;
  late final S _scope;

  void _onChangeListener(T value) {
    setState(() {
      _value = value;
    });
  }

  @override
  void initState() {
    super.initState();

    _scope = VerionScopeProvider.of<S>(context);

    _derive = _scope.derive((sub) => widget.derive(sub, _scope));
    _value = _derive.value;

    _derive.addListener(_onChangeListener);
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
