import 'package:oxidized/oxidized.dart';

mixin ComparisonOperatorsFromComparable<T> implements Comparable<T> {
  bool operator <(T other) => compareTo(other) < 0;
  bool operator <=(T other) => compareTo(other) <= 0;
  bool operator >(T other) => compareTo(other) > 0;
  bool operator >=(T other) => compareTo(other) >= 0;
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
