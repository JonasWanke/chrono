import 'package:meta/meta.dart';

@internal
mixin ComparisonOperatorsFromComparable<T> implements Comparable<T> {
  bool operator <(T other) => compareTo(other) < 0;
  bool operator <=(T other) => compareTo(other) <= 0;
  bool operator >(T other) => compareTo(other) > 0;
  bool operator >=(T other) => compareTo(other) >= 0;
}

@internal
extension LetExtension<T extends Object> on T {
  R let<R>(R Function(T) block) => block(this);
}
