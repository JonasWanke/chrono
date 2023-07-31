import 'package:fixed/fixed.dart';
import 'package:oxidized/oxidized.dart';

mixin ComparisonOperatorsFromComparable<T> implements Comparable<T> {
  bool operator <(T other) => compareTo(other) < 0;
  bool operator <=(T other) => compareTo(other) <= 0;
  bool operator >(T other) => compareTo(other) > 0;
  bool operator >=(T other) => compareTo(other) >= 0;
}

extension FixedChronoInternal on Fixed {
  (BigInt, Fixed) get integerAndDecimalParts {
    final scaleFactor = this.scaleFactor;
    final integerPart = minorUnits ~/ scaleFactor;
    final decimalPart =
        Fixed.fromBigInt(minorUnits - integerPart * scaleFactor, scale: scale);
    return (integerPart, decimalPart);
  }

  double toFixedScale(int fractionalDigits) {
    assert(fractionalDigits >= 0);
    if (scale > fractionalDigits) {
      return minorUnits / BigInt.from(10).pow(scale - fractionalDigits);
    }
    if (scale < fractionalDigits) {
      return (minorUnits * BigInt.from(10).pow(fractionalDigits - scale))
          .toDouble();
    }
    return minorUnits.toDouble();
  }
}

extension ResultWithStringErrorChronoInternal<T extends Object>
    on Result<T, String> {
  T unwrapOrThrowAsFormatException() {
    return switch (this) {
      Ok(:final value) => value,
      Err(:final error) => throw FormatException(error),
    };
  }
}
