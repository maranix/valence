/// Default equality check using [identical] and the `==` operator.
bool defaultEquals<T>(T a, T b) => identical(a, b) || (a == b);
