import 'package:verion/src/core/base.dart';

typedef VoidCallback = void Function();

typedef ValueCallback<T> = void Function(T);

typedef EqualityCallback<T> = bool Function(T a, T b);

typedef SubscribeCallback = S Function<S>(ReadableVerion<S>);
