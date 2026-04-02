abstract base class Action<T> {
  const Action({String? label}) : _label = label;

  final String? _label;

  String get label => _label ?? runtimeType.toString();

  T reduce(T state);
}
