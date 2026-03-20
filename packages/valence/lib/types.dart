typedef EqualityFn<T> = bool Function(T a, T b);

typedef MutatorFn<T> = T Function(T val);

typedef ValueCallback<T> = T Function();

typedef VoidCallback = void Function();
