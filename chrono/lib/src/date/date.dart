import 'dart:core' as core;
import 'dart:core';

import 'package:cldr/cldr.dart' hide Days;
import 'package:clock/clock.dart';
import 'package:dartx/dartx.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:oxidized/oxidized.dart';

import '../date_time/date_time.dart';
import '../formatting.dart';
import '../json.dart';
import '../parser.dart';
import '../time/time.dart';
import '../utils.dart';
import 'duration.dart';
import 'era.dart';
import 'month/month.dart';
import 'month/month_day.dart';
import 'month/year_month.dart';
import 'ordinal_date.dart';
import 'week/week_date.dart';
import 'week/year_week.dart';
import 'weekday.dart';
import 'year.dart';

part 'date.freezed.dart';

/// A date in the ISO 8601 calendar, e.g., April 23, 2023.
///
/// The date is represented by a [YearMonth] (= [Year] + [Month]) and a [day]
/// of the month.
///
/// See also:
///
/// - [WeekDate], which represents a date by a [YearWeek] and a [Weekday].
/// - [OrdinalDate], which represents a date by a [Year] and a day of the year.
@immutable
final class Date
    with ComparisonOperatorsFromComparable<Date>
    implements Comparable<Date> {
  static Result<Date, String> from(Year year, Month month, int day) =>
      fromYearMonthAndDay(YearMonth(year, month), day);

  static Result<Date, String> fromYearMonthAndDay(
    YearMonth yearMonth,
    int day,
  ) {
    if (day < 1 || day > yearMonth.length.inDays) {
      return Err('Invalid day for $yearMonth: $day');
    }
    return Ok(Date._(yearMonth, day));
  }

  static Result<Date, String> fromYearAndMonthDay(
    Year year,
    MonthDay monthDay,
  ) =>
      from(year, monthDay.month, monthDay.day);

  const Date._(this.yearMonth, this.day);

  /// The UNIX epoch: 1970-01-01.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static const unixEpoch = Date._(YearMonth(Year.unixEpoch, Month.january), 1);

  /// The date corresponding to the given number of days since the [unixEpoch].
  factory Date.fromDaysSinceUnixEpoch(Days sinceUnixEpoch) {
    // https://howardhinnant.github.io/date_algorithms.html#civil_from_days
    var daysSinceUnixEpoch = sinceUnixEpoch.inDays;
    daysSinceUnixEpoch += 719468;

    final era = (daysSinceUnixEpoch >= 0
            ? daysSinceUnixEpoch
            : daysSinceUnixEpoch - 146096) ~/
        146097;

    final dayOfEra = daysSinceUnixEpoch % 146097;
    assert(0 <= dayOfEra && dayOfEra <= 146096);

    final yearOfEra = (dayOfEra -
            dayOfEra ~/ 1460 +
            dayOfEra ~/ 36524 -
            dayOfEra ~/ 146096) ~/
        365;
    assert(0 <= yearOfEra && yearOfEra <= 399);

    final shiftedYear = yearOfEra + era * 400;

    final dayOfYear =
        dayOfEra - (yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100);
    assert(0 <= dayOfYear && dayOfYear <= 365);

    final shiftedMonth = (dayOfYear * 5 + 2) ~/ 153;
    assert(0 <= shiftedMonth && shiftedMonth <= 11);

    final day = dayOfYear - (shiftedMonth * 153 + 2) ~/ 5 + 1;
    assert(1 <= day && day <= 31);

    final (year, month) = shiftedMonth < 10
        ? (shiftedYear, shiftedMonth + 3)
        : (shiftedYear + 1, shiftedMonth - 9);
    assert(1 <= month && month <= 12);

    return Date._(
      YearMonth(Year(year), Month.fromNumber(month).unwrap()),
      day,
    );
  }

  factory Date.todayInLocalZone({Clock? clock}) =>
      DateTime.nowInLocalZone(clock: clock).date;
  factory Date.todayInUtc({Clock? clock}) =>
      DateTime.nowInUtc(clock: clock).date;

  final YearMonth yearMonth;
  Year get year => yearMonth.year;
  Month get month => yearMonth.month;

  /// The one-based day of the month.
  final int day;

  /// The one-based day of the year.
  int get dayOfYear {
    // https://en.wikipedia.org/wiki/Ordinal_date#Zeller-like
    final isJanuaryOrFebruary = this.month <= Month.february;
    final month =
        isJanuaryOrFebruary ? this.month.number + 12 : this.month.number;
    final marchBased = (153 * ((month - 3) % 12) + 2) ~/ 5 + day;
    return isJanuaryOrFebruary
        ? marchBased - 306
        : marchBased + 59 + (year.isLeapYear ? 1 : 0);
  }

  MonthDay get monthDay => MonthDay.from(month, day).unwrap();

  /// This date, represented as an [OrdinalDate].
  OrdinalDate get asOrdinalDate => OrdinalDate.from(year, dayOfYear).unwrap();

  YearWeek get yearWeek {
    // Algorithm from https://en.wikipedia.org/wiki/ISO_week_date#Algorithms
    final weekOfYear = (dayOfYear - weekday.number + 10) ~/ 7;
    return switch (weekOfYear) {
      0 => year.previous.lastWeek,
      53 when year.numberOfWeeks == 52 => year.next.firstWeek,
      _ => YearWeek.from(year, weekOfYear).unwrap()
    };
  }

  Weekday get weekday =>
      Weekday.fromNumber((daysSinceUnixEpoch.inDays + 3) % 7 + 1).unwrap();

  /// This date, represented as a [WeekDate].
  WeekDate get asWeekDate => WeekDate(yearWeek, weekday);

  /// The number of days since the [unixEpoch].
  Days get daysSinceUnixEpoch {
    // https://howardhinnant.github.io/date_algorithms.html#days_from_civil
    final (year, month) = this.month <= Month.february
        ? (this.year.number - 1, this.month.number + 9)
        : (this.year.number, this.month.number - 3);

    final era = (year >= 0 ? year : year - 399) ~/ 400;

    final yearOfEra = year - era * 400;
    assert(0 <= yearOfEra && yearOfEra <= 399);

    final dayOfYear = (month * 153 + 2) ~/ 5 + day - 1;
    assert(0 <= dayOfYear && dayOfYear <= 365);

    final dayOfEra =
        yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
    assert(0 <= dayOfEra && dayOfEra <= 146096);

    return Days(era * 146097 + dayOfEra - 719468);
  }

  bool isTodayInLocalZone({Clock? clock}) =>
      this == Date.todayInLocalZone(clock: clock);
  bool isTodayInUtc({Clock? clock}) => this == Date.todayInUtc(clock: clock);

  /// A [DateTime] combining this [Date] and the given [time].
  DateTime at(Time time) => DateTime(this, time);

  /// A [DateTime] at [Time.midnight] on this date.
  DateTime get atMidnight => at(Time.midnight);

  /// A [DateTime] at [Time.noon] on this date.
  DateTime get atNoon => at(Time.noon);

  /// Adds the given [duration] to this date.
  ///
  /// The calculation is done as follows:
  ///
  /// 1. Add the months of the duration. If the day of the month is greater than
  ///    the number of days in the resulting month, set it to the last day of
  ///    that month.
  /// 2. Add the days of the duration, potentially updating the year and month
  ///    again.
  ///
  /// Examples:
  ///
  /// - 2023-03-31 + 1 month = 2023-04-30, since April only has 30 days.
  /// - 2023-03-31 + 1 month and 1 day = 2023-05-01
  Date operator +(DaysDuration duration) {
    final CompoundDaysDuration(:months, :days) =
        duration.asCompoundDaysDuration;
    final yearMonthWithMonths = yearMonth + months;
    final dateWithMonths = Date._(
      yearMonthWithMonths,
      day.coerceAtMost(yearMonthWithMonths.length.inDays),
    );

    return days.inDays == 0
        ? dateWithMonths
        : Date.fromDaysSinceUnixEpoch(dateWithMonths.daysSinceUnixEpoch + days);
  }

  Date operator -(DaysDuration duration) => this + (-duration);

  /// The date after this one.
  Date get next => this + const Days(1);

  /// The date before this one.
  Date get previous => this - const Days(1);

  /// Returns `this - other` as a number of [Days].
  Days difference(Date other) => daysSinceUnixEpoch - other.daysSinceUnixEpoch;

  /// The next-closest date with the given [weekday].
  ///
  /// If this date already falls on the given [weekday], it is returned.
  Date nextOrSame(Weekday weekday) =>
      this + this.weekday.untilNextOrSame(weekday);

  /// The next-closest previous date with the given [weekday].
  ///
  /// If this date already falls on the given [weekday], it is returned.
  Date previousOrSame(Weekday weekday) =>
      this + this.weekday.untilPreviousOrSame(weekday);

  Result<Date, String> copyWith({
    YearMonth? yearMonth,
    Year? year,
    Month? month,
    int? day,
  }) {
    assert(yearMonth == null || (year == null && month == null));

    return Date.fromYearMonthAndDay(
      yearMonth ?? YearMonth(year ?? this.year, month ?? this.month),
      day ?? this.day,
    );
  }

  @override
  int compareTo(Date other) {
    final result = yearMonth.compareTo(other.yearMonth);
    if (result != 0) return result;

    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Date && yearMonth == other.yearMonth && day == other.day);
  }

  @override
  int get hashCode => Object.hash(yearMonth, day);

  @override
  String toString() {
    final day = this.day.toString().padLeft(2, '0');
    return '$yearMonth-$day';
  }
}

/// Encodes a [Date] as an ISO 8601 string, e.g., “2023-04-23”.
class DateAsIsoStringJsonConverter
    extends JsonConverterWithParserResult<Date, String> {
  const DateAsIsoStringJsonConverter();

  @override
  Result<Date, FormatException> resultFromJson(String json) =>
      Parser.parseDate(json);
  @override
  String toJson(Date object) => object.toString();
}

class LocalizedDateFormatter extends LocalizedFormatter<Date> {
  const LocalizedDateFormatter(super.localeData, this.style);

  final DateStyle style;

  @override
  String format(Date value) {
    final dateFormats = localeData.dates.calendars.gregorian.dateFormats;

    return style.when(
      defaultFormat: (width) => dateFormats[width]
          .pattern
          .map(
            (it) => it.when(
              literal: (value) => value,
              field: (field) => formatField(value, field),
            ),
          )
          .join(),
    );
  }

  String formatField(Date value, DateField field) {
    return field.when(
      era: (style) =>
          LocalizedEraFormatter(localeData, style).format(value.year.era),
      year: (style) =>
          LocalizedYearFormatter(localeData, style).format(value.year),
      weekBasedYear: (style) => LocalizedYearFormatter(localeData, style)
          .format(value.yearWeek.weekBasedYear),
      extendedYear: (_) => throw UnimplementedError(),
      cyclicYearName: (_) => throw UnimplementedError(),
      relatedGregorianYear: (_) => throw UnimplementedError(),
      quarter: (_) => throw UnimplementedError(),
      month: (style) =>
          LocalizedMonthFormatter(localeData, style).format(value.month),
      // TODO(JonasWanke): use localized numbers
      weekOfYear: (isPadded) =>
          value.yearWeek.week.toString().padLeft(isPadded ? 2 : 1, '0'),
      weekOfMonth: () => throw UnimplementedError(),
      // TODO(JonasWanke): use localized numbers
      dayOfMonth: (isPadded) =>
          value.day.toString().padLeft(isPadded ? 2 : 1, '0'),
      // TODO(JonasWanke): use localized numbers
      dayOfYear: (padding) =>
          value.dayOfYear.toString().padLeft(padding.asInt, '0'),
      dayOfWeekInMonth: () => throw UnimplementedError(),
      modifiedJulianDay: () => throw UnimplementedError(),
      weekday: (style) =>
          LocalizedWeekdayFormatter(localeData, style).format(value.weekday),
    );
  }
}

@freezed
class DateStyle with _$DateStyle {
  // TODO(JonasWanke): customizable component formats

  const factory DateStyle.defaultFormat({
    required DateOrTimeFormatWidth width,
  }) = _DateStyleFormat;

  const DateStyle._();
}
