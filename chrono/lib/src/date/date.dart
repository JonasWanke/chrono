import 'dart:math';

import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../codec.dart';
import '../date_time/date_time.dart';
import '../parser.dart';
import '../time/time.dart';
import '../utils.dart';
import 'duration.dart';
import 'month/month.dart';
import 'month/month_day.dart';
import 'month/year_month.dart';
import 'week/iso_year_week.dart';
import 'week/week_config.dart';
import 'week/year_week.dart';
import 'weekday.dart';
import 'year.dart';

/// A date in the ISO 8601 calendar, e.g., April 23, 2023.
///
/// The date is represented by a [YearMonth] (= [Year] + [Month]) and a [day]
/// of the month.
///
/// This class does not store any time or timezone information.
@immutable
final class Date
    with ComparisonOperatorsFromComparable<Date>
    implements Comparable<Date>, Step<Date> {
  static Result<Date, String> from(Year year, Month month, int day) =>
      fromYearMonthAndDay(YearMonth(year, month), day);
  static Result<Date, String> fromRaw(int year, int month, int day) =>
      Month.fromNumber(month).andThen((month) => from(Year(year), month, day));

  static Result<Date, String> fromYearMonthAndDay(
    YearMonth yearMonth,
    int day,
  ) {
    if (day < 1 || day > yearMonth.length.inDays) {
      return Err('Invalid day for $yearMonth: $day');
    }
    return Ok(Date._unchecked(yearMonth, day));
  }

  static Result<Date, String> fromYearAndMonthDay(
    Year year,
    MonthDay monthDay,
  ) =>
      from(year, monthDay.month, monthDay.day);

  /// Creates a date from a [Year] and a one-based ordinal day of the year,
  /// e.g., the 113th day of 2023.
  static Result<Date, String> fromYearAndOrdinal(Year year, int dayOfYear) {
    if (dayOfYear < 1 || dayOfYear > year.length.inDays) {
      return Err('Invalid day of year for year $year: $dayOfYear');
    }

    int firstDayOfYear(Month month) {
      final firstDayOfYearList = year.isCommonYear
          ? const [1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
          : const [1, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306, 336];
      return firstDayOfYearList[month.index];
    }

    final rawMonth = YearMonth(
      year,
      Month.fromIndex((dayOfYear - 1) ~/ 31).unwrap(),
    );
    final monthEnd =
        firstDayOfYear(rawMonth.month) + rawMonth.length.inDays - 1;
    final month = dayOfYear > monthEnd ? rawMonth.next : rawMonth;

    final dayOfMonth = dayOfYear - firstDayOfYear(month.month) + 1;
    return Ok(Date._unchecked(month, dayOfMonth));
  }

  /// Creates a date from a year week and weekday, e.g., Sunday in the 16th week
  /// of 2023.
  static Date fromIsoYearWeekAndWeekday(
    IsoYearWeek isoYearWeek,
    Weekday weekday,
  ) {
    // https://en.wikipedia.org/wiki/ISO_week_date#Calculating_an_ordinal_or_month_date_from_a_week_date
    final january4 =
        Date.from(isoYearWeek.weekBasedYear, Month.january, 4).unwrap();

    final rawDayOfYear = Days.perWeek * isoYearWeek.week +
        weekday.isoNumber -
        (january4.weekday.isoNumber + 3);
    final Year year;
    final int dayOfYear;
    if (rawDayOfYear < 1) {
      year = isoYearWeek.weekBasedYear - const Years(1);
      dayOfYear = rawDayOfYear + year.length.inDays;
    } else {
      final daysInCurrentYear = isoYearWeek.weekBasedYear.length.inDays;
      if (rawDayOfYear > daysInCurrentYear) {
        year = isoYearWeek.weekBasedYear + const Years(1);
        dayOfYear = rawDayOfYear - daysInCurrentYear;
      } else {
        year = isoYearWeek.weekBasedYear;
        dayOfYear = rawDayOfYear;
      }
    }
    return Date.fromYearAndOrdinal(year, dayOfYear).unwrap();
  }

  const Date._unchecked(this.yearMonth, this.day);

  /// The UNIX epoch: 1970-01-01.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static const unixEpoch =
      Date._unchecked(YearMonth(Year.unixEpoch, Month.january), 1);

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

    return Date._unchecked(
      YearMonth(Year(year), Month.fromNumber(month).unwrap()),
      day,
    );
  }

  /// Creates a Chrono [Date] from a Dart Core [DateTime].
  ///
  /// This uses the [DateTime.year], [DateTime.month], and [DateTime.day]
  /// getters and ignores whether that [ÐateTime] is in UTC or the local
  /// timezone.
  Date.fromCore(DateTime dateTime)
      : this._unchecked(
          YearMonth(
            Year(dateTime.year),
            Month.fromNumber(dateTime.month).unwrap(),
          ),
          dateTime.day,
        );
  factory Date.todayInLocalZone({Clock? clock}) =>
      CDateTime.nowInLocalZone(clock: clock).date;
  factory Date.todayInUtc({Clock? clock}) =>
      CDateTime.nowInUtc(clock: clock).date;

  static final _streamEverySecond =
      Stream<void>.periodic(const Duration(seconds: 1)).asBroadcastStream();
  static Stream<Date> streamInLocalZone({Clock? clock}) {
    return _streamEverySecond
        .map((_) => Date.todayInLocalZone(clock: clock))
        .distinct();
  }

  static Stream<Date> streamInUtc({Clock? clock}) {
    return _streamEverySecond
        .map((_) => Date.todayInUtc(clock: clock))
        .distinct();
  }

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

  IsoYearWeek get isoYearWeek {
    // Algorithm from https://en.wikipedia.org/wiki/ISO_week_date#Algorithms
    final weekOfYear = (dayOfYear - weekday.isoNumber + 10) ~/ Days.perWeek;
    return switch (weekOfYear) {
      0 => year.previous.isoWeeks.endInclusive,
      53 when year.numberOfIsoWeeks == 52 => year.next.isoWeeks.start,
      _ => IsoYearWeek.from(year, weekOfYear).unwrap()
    };
  }

  YearWeek yearWeek(WeekConfig config) {
    final first = year.firstDayOfWeekBasedYear(config);
    final last = year.lastDayOfWeekBasedYear(config);

    final Year weekBasedYear;
    final int week;
    if (this < first) {
      weekBasedYear = year.previous;
      week = weekBasedYear.numberOfWeeks(config);
    } else if (this > last) {
      weekBasedYear = year.next;
      week = 1;
    } else {
      final diff = differenceInDays(first);
      weekBasedYear = year;
      week = 1 + diff.inDays ~/ Days.perWeek;
    }
    return YearWeek.from(weekBasedYear, week, config).unwrap();
  }

  Weekday get weekday {
    return Weekday.fromIndex((daysSinceUnixEpoch.inDays + 3) % Days.perWeek)
        .unwrap();
  }

  /// Is this the 1st, 2nd, 3rd, 4th, or 5th occurrence of its [weekday] during
  /// this month?
  int get weekdayInMonthIndex => (day - 1) ~/ Days.perWeek + 1;

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

  /// A [CDateTime] combining this [Date] and the given [time].
  CDateTime at(Time time) => CDateTime(this, time);

  /// A [CDateTime] at [Time.midnight] on this date.
  CDateTime get atMidnight => at(Time.midnight);

  /// A [CDateTime] at [Time.noon] on this date.
  CDateTime get atNoon => at(Time.noon);

  /// The [CDateTime]s in this date.
  Range<CDateTime> get dateTimes => atMidnight.rangeUntil(next.atMidnight);

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
  Date operator +(CalendarDuration duration) {
    final CompoundCalendarDuration(:months, :days) =
        duration.asCompoundCalendarDuration;
    final yearMonthWithMonths = yearMonth + months;
    final dateWithMonths = Date._unchecked(
      yearMonthWithMonths,
      min(day, yearMonthWithMonths.length.inDays),
    );

    return days.inDays == 0
        ? dateWithMonths
        : Date.fromDaysSinceUnixEpoch(dateWithMonths.daysSinceUnixEpoch + days);
  }

  Date operator -(CalendarDuration duration) => this + (-duration);

  /// The date after this one.
  Date get next => this + const Days(1);

  /// The date before this one.
  Date get previous => this - const Days(1);

  /// Returns `this - other` as a number of [Days].
  Days differenceInDays(Date other) =>
      daysSinceUnixEpoch - other.daysSinceUnixEpoch;

  /// Returns a number of [Months] and [Days] so that `this + months + days ==
  /// other`.
  ///
  /// The returned [Months] and [Days] are both `>= 0` or both `<= 0`.
  (Months, Days) untilInMonthsDays(Date other) {
    var months = other.yearMonth.difference(yearMonth);
    var days = Days(other.day - day);
    if (months.isPositive && days.isNegative) {
      months -= const Months(1);
      days = other.daysSinceUnixEpoch - (this + months).daysSinceUnixEpoch;
    } else if (months.isNegative && days.isPositive) {
      months += const Months(1);
      days -= other.yearMonth.length;
    }
    return (months, days);
  }

  /// Returns a number of [Years], [Months], and [Days] so that `this + years +
  /// months + days == other`.
  ///
  /// The returned [Years], [Months]y and [Days] are all `>= 0` or all `<= 0`.
  (Years, Months, Days) untilInYearsMonthsDays(Date other) {
    final (monthsRaw, days) = untilInMonthsDays(other);
    final (years, months) = monthsRaw.splitYearsMonths;
    return (years, months, days);
  }

  // TODO: untilInWeeksDays, untilInYearsDays, untilInMonthsWeeksDays, etc.

  /// Calculates the age of someone on [onDate] who was born on `this` date.
  ///
  /// If [onDate] is not provided, the current date in the local zone is used.
  Years age({Date? onDate}) {
    onDate ??= Date.todayInLocalZone();

    var age = onDate.year.difference(year);
    if (monthDay > onDate.monthDay) age += const Years(1);
    return age;
  }

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
  Date stepBy(int count) => this + Days(count);
  @override
  int stepsUntil(Date other) => other.differenceInDays(this).inDays;

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

  String toOrdinalDateString() {
    final dayOfYear = this.dayOfYear.toString().padLeft(3, '0');
    return '$year-$dayOfYear';
  }

  String toWeekDateString() => '$isoYearWeek-${weekday.isoNumber}';
}

extension RangeOfDateChrono on Range<Date> {
  /// The [CDateTime]s in these dates.
  Range<CDateTime> get dateTimes => start.atMidnight.rangeUntil(end.atMidnight);
}

extension RangeInclusiveOfDateChrono on RangeInclusive<Date> {
  /// The [CDateTime]s in these dates.
  Range<CDateTime> get dateTimes => exclusive.dateTimes;
}

/// Encodes a [Date] as an ISO 8601 string, e.g., “2023-04-23”.
class DateAsIsoStringCodec extends CodecWithParserResult<Date, String> {
  const DateAsIsoStringCodec();

  @override
  String encode(Date input) => input.toString();
  @override
  Result<Date, FormatException> decodeAsResult(String encoded) =>
      Parser.parseDate(encoded);
}

/// Encodes a [Date] as an ordinal date ISO 8601 string, e.g., “2023-113”.
class DateAsOrdinalDateIsoStringCodec
    extends CodecWithParserResult<Date, String> {
  const DateAsOrdinalDateIsoStringCodec();

  @override
  String encode(Date input) => input.toOrdinalDateString();
  @override
  Result<Date, FormatException> decodeAsResult(String encoded) =>
      Parser.parseOrdinalDate(encoded);
}

/// Encodes a [Date] as a week date ISO 8601 string, e.g., “2023-W16-7”.
class DateAsWeekDateIsoStringCodec extends CodecWithParserResult<Date, String> {
  const DateAsWeekDateIsoStringCodec();

  @override
  String encode(Date input) => input.toWeekDateString();
  @override
  Result<Date, FormatException> decodeAsResult(String encoded) =>
      Parser.parseWeekDate(encoded);
}
