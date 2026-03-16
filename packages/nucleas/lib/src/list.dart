import 'dart:typed_data';

final class GrowableUint32List {
  GrowableUint32List([int initialCapacity = 4]) : _data = .new(initialCapacity);

  Uint32List _data;
  int _length = 0;

  int get length => _length;

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length > 0;

  int operator [](int index) => _data[index];

  int get last {
    if (isEmpty) throw StateError("No Elements");

    return _data[_length - 1];
  }

  void add(int id) {
    if (_length == _data.length) {
      final newData = Uint32List(_data.length * 2);
      newData.setAll(0, _data);
      _data = newData;
    }

    _data[_length] = id;
    _length += 1;
  }

  void remove(int id) {
    for (var i = 0; i < _length; i++) {
      if (_data[i] == id) {
        // Order doesn't matter, so we just swap the removal id with the last element
        // and decrement the _length by 1
        _data[i] = _data[_length - 1];
        _length -= 1;
        return;
      }
    }
  }

  int removeLast() {
    if (_length == 0) throw StateError("No Elements");

    // Save the last element
    final item = _data[_length - 1];

    // Decrement length pointer
    _length -= 1;

    // return the last element
    return item;
  }

  bool contains(int id) {
    for (var i = 0; i < _length; i++) {
      if (_data[i] == id) return true;
    }

    return false;
  }

  void clear() {
    _length = 0;
  }
}
