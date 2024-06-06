import 'dart:core' as core;
import 'dart:core';

import 'package:clock/clock.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../json.dart';
import '../parser.dart';
import '../utils.dart';
import 'date.dart';
import 'duration.dart';
import 'month/month.dart';
import 'month/year_month.dart';
import 'ordinal_date.dart';
import 'week/year_week.dart';
import 'weekday.dart';

/// A year in the ISO 8601 calendar, e.g., 2023.
///
/// The [number] corresponds to these years, according to ISO 8601:
///
/// | Value |   Meaning   |
/// |-------|-------------|
/// |  2023 | 2023  CE/AD |
/// |     … |      …      |
/// |     1 |    1  CE/AD |
/// |     0 |    1 BCE/BC |
/// |    -1 |    2 BCE/BC |
/// |     … |      …      |
///
/// There is no limitation on the range of years.
@immutable
final class Year
    with ComparisonOperatorsFromComparable<Year>
    implements Comparable<Year> {
  const Year(this.number);

  /// The UNIX epoch: 1970.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static const unixEpoch = Year(1970);

  factory Year.currentInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).year;
  factory Year.currentInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).year;

  final int number;

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == Year.currentInLocalZone(clock: clock);
  bool isCurrentInUtc({Clock? clock}) =>
      this == Year.currentInUtc(clock: clock);

  /// Whether this year is a common (non-leap) year.
  bool get isCommonYear => !isLeapYear;

  /// Whether this year is a leap year.
  bool get isLeapYear {
    // https://howardhinnant.github.io/date_algorithms.html#is_leap
    return number % 4 == 0 && (number % 100 != 0 || number % 400 == 0);
  }

  Days get length => isLeapYear ? Days.leapYear : Days.normalYear;
  int get numberOfWeeks {
    // https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
    final isLongWeek = lastDay.weekday == Weekday.thursday ||
        previous.lastDay.weekday == Weekday.wednesday;
    return isLongWeek ? 53 : 52;
  }

  /// The first month of this year.
  YearMonth get firstMonth => YearMonth(this, Month.january);

  /// The last month of this year.
  YearMonth get lastMonth => YearMonth(this, Month.december);

  /// An iterable of all months in this year.
  Iterable<YearMonth> get months =>
      Month.values.map((month) => YearMonth(this, month));

  /// The first week of this year.
  YearWeek get firstWeek => YearWeek.from(this, 1).unwrap();

  /// The last week of this year.
  YearWeek get lastWeek => YearWeek.from(this, numberOfWeeks).unwrap();

  /// An iterable of all weeks in this year.
  Iterable<YearWeek> get weeks {
    return Iterable.generate(
      numberOfWeeks,
      (it) => YearWeek.from(this, it + 1).unwrap(),
    );
  }

  /// The first day of this year.
  Date get firstDay => firstMonth.firstDay;

  /// The last day of this year.
  Date get lastDay => lastMonth.lastDay;

  /// The first day of this year as an [OrdinalDate].
  OrdinalDate get firstOrdinalDate => OrdinalDate.from(this, 1).unwrap();

  /// The last day of this year as an [OrdinalDate].
  OrdinalDate get lastOrdinalDate =>
      OrdinalDate.from(this, length.inDays).unwrap();

  /// An iterable of all days in this year.
  Iterable<Date> get days => months.expand((it) => it.days);

  Year operator +(Years duration) => Year(number + duration.inYears);
  Year operator -(Years duration) => Year(number - duration.inYears);

  /// The year after this one.
  Year get next => this + const Years(1);

  /// The year before this one.
  Year get previous => this - const Years(1);

  @override
  int compareTo(Year other) => number.compareTo(other.number);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Year && number == other.number);
  @override
  int get hashCode => number.hashCode;

  @override
  String toString() {
    return switch (number) {
      < 0 => '-${number.abs().toString().padLeft(4, '0')}',
      >= 10000 => '+$number',
      _ => number.toString().padLeft(4, '0'),
    };
  }
}

/// Encodes a year as an ISO 8601 string: `YYYY`, `-YYYY`, or `+YYYYY`.
///
/// The year number is zero-padded to at least four digits. Negative years are
/// prefixed with a minus sign, years with five or more digits are prefixed
/// with a plus sign.
///
/// Examples:
///
/// |  Value |    Meaning   | Encoded |
/// |-------:|-------------:|-----------:|
/// |  12023 | 12023  CE/AD | `"+12023"` |
/// |   2023 |  2023  CE/AD |   `"2023"` |
/// |      1 |     1  CE/AD |   `"0001"` |
/// |      0 |     1 BCE/BC |   `"0000"` |
/// |     -1 |     2 BCE/BC |  `"-0001"` |
/// |  -1234 |  1235 BCE/AD |  `"-1234"` |
/// | -12345 | 12346 BCE/AD | `"-12345"` |
///
/// https://en.wikipedia.org/wiki/ISO_8601#Years
///
/// See also:
/// - [YearAsIntJsonConverter], which encodes a year as an integer.
class YearAsIsoStringJsonConverter
    extends JsonConverterWithParserResult<Year, String> {
  const YearAsIsoStringJsonConverter();

  @override
  Result<Year, FormatException> resultFromJson(String json) =>
      Parser.parseYear(json);
  @override
  String toJson(Year object) => object.toString();
}

/// Encodes a [Year] as an integer.
///
/// See also:
/// - [YearAsIsoStringJsonConverter], which encodes a year as a string.
@immutable
class YearAsIntJsonConverter extends JsonConverter<Year, int> {
  const YearAsIntJsonConverter();

  @override
  Year fromJson(int json) => Year(json);

  @override
  int toJson(Year object) => object.number;
}
