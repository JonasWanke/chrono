import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:dartx/dartx.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../date_time/date_time.dart';
import '../parser.dart';
import '../time/time.dart';
import '../utils.dart';
import 'duration.dart';
import 'month/month.dart';
import 'month/year_month.dart';
import 'ordinal_date.dart';
import 'week/week_date.dart';
import 'week/year_week.dart';
import 'weekday.dart';
import 'year.dart';

/// A date in the ISO 8601 calendar.
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
  static Result<Date, String> fromYearMonthAndDay(
    YearMonth yearMonth,
    int day,
  ) {
    if (day < 1 || day > yearMonth.lengthInDays.value) {
      return Err('Invalid day for $yearMonth: $day');
    }
    return Ok(Date.fromYearMonthAndDayUnchecked(yearMonth, day));
  }

  factory Date.fromYearMonthAndDayThrowing(YearMonth yearMonth, int day) =>
      fromYearMonthAndDay(yearMonth, day).unwrap();
  const Date.fromYearMonthAndDayUnchecked(this.yearMonth, this.day);

  static Result<Date, String> from(
    Year year, [
    Month month = Month.january,
    int day = 1,
  ]) =>
      fromYearMonthAndDay(YearMonth(year, month), day);
  factory Date.fromThrowing(
    Year year, [
    Month month = Month.january,
    int day = 1,
  ]) =>
      from(year, month, day).unwrap();
  Date.fromUnchecked(
    Year year, [
    Month month = Month.january,
    int day = 1,
  ]) : this.fromYearMonthAndDayUnchecked(YearMonth(year, month), day);

  /// The UNIX epoch: 1970-01-01.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static const unixEpoch = Date.fromYearMonthAndDayUnchecked(
    YearMonth(Year(1970), Month.january),
    1,
  );

  /// The date corresponding to the given number of days since the [unixEpoch].
  factory Date.fromDaysSinceUnixEpoch(Days sinceUnixEpoch) {
    // https://howardhinnant.github.io/date_algorithms.html#civil_from_days
    var daysSinceUnixEpoch = sinceUnixEpoch.value;
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

    return Date.fromYearMonthAndDayUnchecked(
      YearMonth(Year(year), Month.fromNumberUnchecked(month)),
      day,
    );
  }

  Date.fromCore(core.DateTime dateTime)
      : this.fromYearMonthAndDayUnchecked(
          YearMonth.fromCore(dateTime),
          dateTime.day,
        );
  Date.todayInLocalZone({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now().toLocal());
  Date.todayInUtc({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now().toUtc());

  factory Date.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<Date, FormatException> parse(String value) =>
      Parser.parseDate(value);

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

  /// This date, represented as an [OrdinalDate].
  OrdinalDate get asOrdinalDate => OrdinalDate.fromUnchecked(year, dayOfYear);

  YearWeek get yearWeek {
    // Algorithm from https://en.wikipedia.org/wiki/ISO_week_date#Algorithms
    final weekOfYear = (dayOfYear - weekday.number + 10) ~/ 7;
    return switch (weekOfYear) {
      0 => year.previous.lastWeek,
      53 when year.numberOfWeeks == 52 => year.next.firstWeek,
      _ => YearWeek.fromUnchecked(year, weekOfYear)
    };
  }

  Weekday get weekday =>
      Weekday.fromNumberUnchecked((daysSinceUnixEpoch.value + 3) % 7 + 1);

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

  bool isTodayInLocalZone({Clock? clockOverride}) =>
      this == Date.todayInLocalZone(clockOverride: clockOverride);
  bool isTodayInUtc({Clock? clockOverride}) =>
      this == Date.todayInUtc(clockOverride: clockOverride);

  /// A [DateTime] combining this [Date] and the given [time].
  DateTime at(Time time) => DateTime(this, time);

  /// A [DateTime] at [Time.midnight] on this date.
  DateTime get atMidnight => at(Time.midnight);

  /// A [DateTime] at [Time.noon] on this date.
  DateTime get atNoon => at(Time.noon);

  Date operator +(DaysDuration duration) {
    final CompoundDaysDuration(:months, :days) =
        duration.asCompoundDaysDuration;
    final yearMonthWithMonths = yearMonth + months;
    final dateWithMonths = Date.fromYearMonthAndDayUnchecked(
      yearMonthWithMonths,
      day.coerceAtMost(yearMonthWithMonths.lengthInDays.value),
    );

    return days.value == 0
        ? dateWithMonths
        : Date.fromDaysSinceUnixEpoch(dateWithMonths.daysSinceUnixEpoch + days);
  }

  Date operator -(DaysDuration duration) => this + (-duration);

  /// The date after this one.
  Date get next => this + const Days(1);

  /// The date before this one.
  Date get previous => this - const Days(1);

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

  Date copyWithThrowing({
    YearMonth? yearMonth,
    Year? year,
    Month? month,
    int? day,
  }) {
    assert(yearMonth == null || (year == null && month == null));

    return Date.fromYearMonthAndDayThrowing(
      yearMonth ?? YearMonth(year ?? this.year, month ?? this.month),
      day ?? this.day,
    );
  }

  Date copyWithUnchecked({
    YearMonth? yearMonth,
    Year? year,
    Month? month,
    int? day,
  }) {
    assert(yearMonth == null || (year == null && month == null));

    return Date.fromYearMonthAndDayUnchecked(
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

  String toJson() => toString();
}
