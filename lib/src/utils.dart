import 'package:fixed/fixed.dart';
import 'package:oxidized/oxidized.dart';

mixin ComparisonOperatorsFromComparable<T> implements Comparable<T> {
  bool operator <(T other) => compareTo(other) < 0;
  bool operator <=(T other) => compareTo(other) <= 0;
  bool operator >(T other) => compareTo(other) > 0;
  bool operator >=(T other) => compareTo(other) >= 0;
}

extension FixedPlainDateTimeInternal on Fixed {
  (BigInt, Fixed) get integerAndDecimalParts {
    final scaleFactor = this.scaleFactor;
    final integerPart = minorUnits ~/ scaleFactor;
    final decimalPart =
        Fixed.fromBigInt(minorUnits - integerPart * scaleFactor, scale: scale);
    return (integerPart, decimalPart);
  }
}

extension ResultWithStringErrorPlainDateTimeInternal<T extends Object>
    on Result<T, String> {
  T unwrapOrThrowAsFormatException() {
    if (isErr()) throw FormatException(unwrapErr());
    return unwrap();
  }
}
