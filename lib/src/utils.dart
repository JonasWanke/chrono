import 'package:fixed/fixed.dart';
import 'package:oxidized/oxidized.dart';

mixin ComparisonOperatorsFromComparable<T> implements Comparable<T> {
  bool operator <(T other) => compareTo(other) < 0;
  bool operator <=(T other) => compareTo(other) <= 0;
  bool operator >(T other) => compareTo(other) > 0;
  bool operator >=(T other) => compareTo(other) >= 0;
}

extension FixedPlainDateTimeInternal on Fixed {
  // `Fixed`'s finals have a scale of 16, which we don't need.
  static final zero = Fixed.fromBigInt(BigInt.zero, scale: 0);
  static final one = Fixed.fromBigInt(BigInt.one, scale: 0);

  int get secondsAsMicroseconds {
    // `Fixed`'s `*` operator performs rounding to a `double` internally,
    // causing precision loss.
    return Fixed.copyWith(this, scale: 6).minorUnits.toInt();
  }
}

extension ResultWithStringErrorPlainDateTimeInternal<T extends Object>
    on Result<T, String> {
  T unwrapOrThrowAsFormatException() {
    if (isErr()) throw FormatException(unwrapErr());
    return unwrap();
  }
} 
