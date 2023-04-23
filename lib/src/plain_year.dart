import 'package:meta/meta.dart';

import 'utils.dart';

/// | Value |   Meaning   |
/// |-------|-------------|
/// |  2023 | 2023  CE/AD |
/// |     … |      …      |
/// |     1 |    1  CE/AD |
/// |     0 |    1 BCE/BC |
/// |    -1 |    2 BCE/BC |
/// |     … |      …      |
@immutable
final class PlainYear
    with ComparisonOperatorsFromComparable<PlainYear>
    implements Comparable<PlainYear> {
  const PlainYear(this.value);
  PlainYear.fromDateTime(DateTime dateTime) : value = dateTime.year;
  const PlainYear.fromJson(int json) : this(json);

  final int value;

  /// Whether this year is a common (non-leap) year.
  bool get isCommonYear => !isLeapYear;

  /// Whether this year is a leap year.
  bool get isLeapYear {
    // https://howardhinnant.github.io/date_algorithms.html#is_leap
    return value % 4 == 0 && (value % 100 != 0 || value % 400 == 0);
  }

  // TODO: isCurrentYearInLocalZone, isCurrentYearInUtc?

  @override
  int compareTo(PlainYear other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PlainYear && value == other.value);
  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    return switch (value) {
      < 0 => '-${value.abs().toString().padLeft(4, '0')}',
      >= 10000 => '+$value',
      _ => value.toString().padLeft(4, '0'),
    };
  }

  int toJson() => value;
}
