import 'dart:core' as core;
import 'dart:core';

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../json.dart';
import '../parser.dart';
import '../utils.dart';
import 'date.dart';
import 'duration.dart';
import 'month/month.dart';
import 'month/year_month.dart';
import 'week/week_date.dart';
import 'week/year_week.dart';
import 'weekday.dart';
import 'year.dart';

/// A date in the ISO 8601 calendar represented by a [Year] and a day of the
/// year, e.g., the 113th day of 2023.
///
/// See also:
///
/// - [Date], which represents a date by a [YearMonth] (= [Year] + [Month]) and
///   a day of the month.
/// - [WeekDate], which represents a date by a [YearWeek] and a [Weekday].
@immutable
final class OrdinalDate
    with ComparisonOperatorsFromComparable<OrdinalDate>
    implements Comparable<OrdinalDate> {
  static Result<OrdinalDate, String> from(Year year, int dayOfYear) {
    if (dayOfYear < 1 || dayOfYear > year.length.inDays) {
      return Err('Invalid day of year for year $year: $dayOfYear');
    }
    return Ok(OrdinalDate._(year, dayOfYear));
  }

  const OrdinalDate._(this.year, this.dayOfYear);

  factory OrdinalDate.todayInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).asOrdinalDate;
  factory OrdinalDate.todayInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).asOrdinalDate;

  final Year year;

  /// The one-based day of the year.
  final int dayOfYear;

  /// This date, represented as a [Date].
  Date get asDate {
    int firstDayOfYear(Month month) {
      final firstDayOfYearList = year.isCommonYear
          ? const [1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
          : const [1, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306, 336];
      return firstDayOfYearList[month.index];
    }

    final rawMonth = YearMonth(
      year,
      Month.fromNumber((dayOfYear - 1) ~/ 31 + 1).unwrap(),
    );
    final monthEnd =
        firstDayOfYear(rawMonth.month) + rawMonth.length.inDays - 1;
    final month = dayOfYear > monthEnd ? rawMonth.next : rawMonth;

    final dayOfMonth = dayOfYear - firstDayOfYear(month.month) + 1;
    return Date.fromYearMonthAndDay(month, dayOfMonth).unwrap();
  }

  /// This date, represented as a [WeekDate].
  WeekDate get asWeekDate => asDate.asWeekDate;

  bool isTodayInLocalZone({Clock? clock}) =>
      this == OrdinalDate.todayInLocalZone(clock: clock);
  bool isTodayInUtc({Clock? clock}) =>
      this == OrdinalDate.todayInUtc(clock: clock);

  OrdinalDate operator +(DaysDuration duration) =>
      (asDate + duration).asOrdinalDate;
  OrdinalDate operator -(DaysDuration duration) => this + (-duration);

  /// The date after this one.
  OrdinalDate get next {
    return dayOfYear == year.length.inDays
        ? (year + const Years(1)).firstOrdinalDate
        : OrdinalDate.from(year, dayOfYear + 1).unwrap();
  }

  /// The date before this one.
  OrdinalDate get previous {
    return dayOfYear == 1
        ? (year - const Years(1)).lastOrdinalDate
        : OrdinalDate.from(year, dayOfYear - 1).unwrap();
  }

  Result<OrdinalDate, String> copyWith({Year? year, int? dayOfYear}) =>
      OrdinalDate.from(year ?? this.year, dayOfYear ?? this.dayOfYear);

  @override
  int compareTo(OrdinalDate other) {
    final result = year.compareTo(other.year);
    if (result != 0) return result;

    return dayOfYear.compareTo(other.dayOfYear);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is OrdinalDate &&
            year == other.year &&
            dayOfYear == other.dayOfYear);
  }

  @override
  int get hashCode => Object.hash(year, dayOfYear);

  @override
  String toString() {
    final dayOfYear = this.dayOfYear.toString().padLeft(3, '0');
    return '$year-$dayOfYear';
  }
}

class OrdinalDateAsIsoStringJsonConverter
    extends JsonConverterWithParserResult<OrdinalDate, String> {
  const OrdinalDateAsIsoStringJsonConverter();

  @override
  Result<OrdinalDate, FormatException> resultFromJson(String json) =>
      Parser.parseOrdinalDate(json);
  @override
  String toJson(OrdinalDate object) => object.toString();
}
