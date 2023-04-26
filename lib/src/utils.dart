import 'package:fixed/fixed.dart';

mixin ComparisonOperatorsFromComparable<T> implements Comparable<T> {
  bool operator <(T other) => compareTo(other) < 0;
  bool operator <=(T other) => compareTo(other) <= 0;
  bool operator >(T other) => compareTo(other) > 0;
  bool operator >=(T other) => compareTo(other) >= 0;
}

extension FixedPlainDateTimeInternal on Fixed {
  int get secondsAsMicroseconds {
    // `Fixed`'s `*` operator performs rounding to a `double` internally,
    // causing precision loss.
    return Fixed.copyWith(this, scale: 6).minorUnits.toInt();
  }
}
