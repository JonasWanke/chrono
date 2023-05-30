import 'package:clock/clock.dart';
import 'package:meta/meta.dart';

import '../utils.dart';
import 'date.dart';
import 'month/month.dart';
import 'month/year_month.dart';
import 'period.dart';
import 'week/year_week.dart';
import 'weekday.dart';

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
  PlainYear.currentInLocalZone({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toLocal());
  PlainYear.currentInUtc({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toUtc());

  const PlainYear.fromJson(int json) : this(json);

  final int value;

  bool isCurrentInLocalZone({Clock? clockOverride}) =>
      this == PlainYear.currentInLocalZone(clockOverride: clockOverride);
  bool isCurrentInUtc({Clock? clockOverride}) =>
      this == PlainYear.currentInUtc(clockOverride: clockOverride);

  /// Whether this year is a common (non-leap) year.
  bool get isCommonYear => !isLeapYear;

  /// Whether this year is a leap year.
  bool get isLeapYear {
    // https://howardhinnant.github.io/date_algorithms.html#is_leap
    return value % 4 == 0 && (value % 100 != 0 || value % 400 == 0);
  }

  Days get lengthInDays => isLeapYear ? const Days(366) : const Days(365);
  int get numberOfWeeks {
    // https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
    Weekday weekdayOfDecember31(PlainYear year) =>
        PlainDate.fromUnchecked(year, PlainMonth.december, 31).weekday;

    final isLongWeek = weekdayOfDecember31(this) == Weekday.thursday ||
        weekdayOfDecember31(previousYear) == Weekday.wednesday;
    return isLongWeek ? 53 : 52;
  }

  PlainYearMonth get firstMonth => PlainYearMonth(this, PlainMonth.january);
  PlainYearMonth get lastMonth => PlainYearMonth(this, PlainMonth.december);
  Iterable<PlainYearMonth> get months =>
      PlainMonth.values.map((month) => PlainYearMonth(this, month));

  PlainYearWeek get firstWeek => PlainYearWeek.fromUnchecked(this, 1);
  PlainYearWeek get lastWeek =>
      PlainYearWeek.fromUnchecked(this, numberOfWeeks);
  Iterable<PlainYearWeek> get weeks {
    return Iterable.generate(
      numberOfWeeks,
      (it) => PlainYearWeek.fromUnchecked(this, it + 1),
    );
  }

  PlainDate get firstDay => firstMonth.firstDay;
  PlainDate get lastDay => lastMonth.lastDay;
  Iterable<PlainDate> get days => months.expand((it) => it.days);

  PlainYear operator +(Years period) => PlainYear(value + period.value);
  PlainYear operator -(Years period) => PlainYear(value - period.value);

  PlainYear get nextYear => this + const Years(1);
  PlainYear get previousYear => this - const Years(1);

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
