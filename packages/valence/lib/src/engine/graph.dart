import 'package:valence/src/engine/node.dart';

abstract interface class Graph {
  factory Graph() = _GraphImpl;

  bool get isTracking;

  void beginTracking();
  List<Source> endTracking();

  void beginProbe(List<Source> sources);
  bool endProbe(int count);

  void recordSource(Source source);
}

final class _GraphImpl implements Graph {
  List<Source>? _probed;
  int _cursor = 0;
  bool _consistent = true;

  final List<List<Source>> _trackingStack = [];

  @override
  bool get isTracking => _trackingStack.isNotEmpty;

  @override
  void beginTracking() => _trackingStack.add([]);

  @override
  List<Source> endTracking() => _trackingStack.removeLast();

  @override
  void beginProbe(List<Source> sources) {
    _probed = sources;
    _cursor = 0;
    _consistent = true;
  }

  @override
  bool endProbe(int count) {
    _probed = null;
    return _consistent && _cursor == count;
  }

  @override
  void recordSource(Source source) {
    if (_trackingStack.isEmpty) {
      _validateProbedSouce(source);
      return;
    }

    final list = _trackingStack.last;
    for (final node in list) {
      if (identical(node, source)) return;
    }

    list.add(source);
  }

  void _validateProbedSouce(Source source) {
    if (_probed == null || !_consistent) return;

    if (_cursor >= _probed!.length || !identical(_probed![_cursor], source)) {
      _consistent = false;
      return;
    }

    _cursor++;
  }
}
