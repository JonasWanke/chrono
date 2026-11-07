import 'dart:math';

import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';

import '../../chrono.dart';
import '../codec.dart';
import '../utils.dart';

/// A date in the ISO 8601 calendar, e.g., April 23, 2023.
///
/// The date is represented by a [YearMonth] (= [Year] + [Month]) and a [day]
/// of the month.
///
/// This class does not store any time or timezone information.
@immutable
final class const Date._unchecked(
  final YearMonth yearMonth,

  /// The one-based day of the month.
  final int day,
) with ComparisonOperatorsFromComparable<Date>, StepUnlimited<Date>
    implements Comparable<Date>, ChronoFormattable<DateFormatItem> {
  new from(Year year, Month month, int day)
    : this._unchecked(
        YearMonth.from(year, month),
        RangeError.checkValueInInterval(
          day,
          1,
          YearMonth.from(year, month).length.inDays,
          'day',
          'Invalid day for ${YearMonth.from(year, month)}.',
        ),
      );
  new(int year, int month, int day)
    : this.from(Year(year), Month.fromNumber(month), day);

  /// Creates a date from a calendar [year], a [weekNumber] (see
  /// [weekNumberStartingOn]), and a [weekday], e.g., Thursday in week 3.
  ///
  /// Week 1 starts at the first [firstDay] of the year, and days before it are
  /// in week 0.
  ///
  /// Throws a [RangeError] if the date isn't in [year].
  factory fromYearAndWeekNumber(
    Year year,
    int weekNumber,
    Weekday weekday, {
    required Weekday firstDay,
  }) {
    final january1 = Date.from(year, Month.january, 1);
    final firstWeekStart =
        january1.weekday.untilNextOrSame(firstDay).inDays + 1;
    final ordinal =
        firstWeekStart +
        (weekNumber - 1) * Days.perWeek +
        weekday.indexFrom(firstDay);
    return year.atOrdinalDay(ordinal);
  }

  /// The UNIX epoch: 1970-01-01.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static const unixEpoch = Date._unchecked(
    YearMonth.from(Year.unixEpoch, Month.january),
    1,
  );

  /// The date corresponding to the given number of days since the [unixEpoch].
  factory fromDaysSinceUnixEpoch(Days sinceUnixEpoch) {
    // https://howardhinnant.github.io/date_algorithms.html#civil_from_days
    var daysSinceUnixEpoch = sinceUnixEpoch.inDays;
    daysSinceUnixEpoch += 719468;

    final era =
        (daysSinceUnixEpoch >= 0
            ? daysSinceUnixEpoch
            : daysSinceUnixEpoch - 146096) ~/
        146097;

    final dayOfEra = daysSinceUnixEpoch % 146097;
    assert(0 <= dayOfEra && dayOfEra <= 146096);

    final yearOfEra =
        (dayOfEra -
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
      YearMonth.from(Year(year), Month.fromNumber(month)),
      day,
    );
  }

  /// Creates a Chrono [Date] from a Dart Core [DateTime].
  ///
  /// This uses the [DateTime.year], [DateTime.month], and [DateTime.day]
  /// getters and ignores whether that [DateTime] is in UTC or the local
  /// timezone.
  new fromCore(DateTime dateTime)
    : this._unchecked(
        YearMonth.from(Year(dateTime.year), Month.fromNumber(dateTime.month)),
        dateTime.day,
      );
  factory todayInLocalZone({Clock? clock}) =>
      CDateTime.nowInLocalZone(clock: clock).date;
  factory todayInUtc({Clock? clock}) => CDateTime.nowInUtc(clock: clock).date;

  static final _streamEverySecond = Stream<void>.periodic(
    const Duration(seconds: 1),
  ).asBroadcastStream();
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

  Year get year => yearMonth.year;
  Quarter get quarter => month.quarter;
  Month get month => yearMonth.month;

  /// The one-based day of the year.
  int get dayOfYear {
    // https://en.wikipedia.org/wiki/Ordinal_date#Zeller-like
    final isJanuaryOrFebruary = this.month <= Month.february;
    final month = isJanuaryOrFebruary
        ? this.month.number + 12
        : this.month.number;
    final marchBased = (153 * ((month - 3) % 12) + 2) ~/ 5 + day;
    return isJanuaryOrFebruary
        ? marchBased - 306
        : marchBased + 59 + (year.isLeapYear ? 1 : 0);
  }

  MonthDay get monthDay => MonthDay.from(month, day);

  /// The week number within the calendar year, where week 1 starts at the first
  /// [firstDay] of the year (from 0 to 53).
  ///
  /// Days before that first [firstDay] are in week 0. This is the numbering of
  /// `%U` ([Weekday.sunday]) and `%W` ([Weekday.monday]) in `strftime`. See
  /// [yearWeek] for weeks that can belong to the neighboring year.
  int weekNumberStartingOn(Weekday firstDay) =>
      (dayOfYear - 1 + Days.perWeek - weekday.indexFrom(firstDay)) ~/
      Days.perWeek;

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
      final diff = daysSince(first);
      weekBasedYear = year;
      week = 1 + diff.inDays ~/ Days.perWeek;
    }
    return YearWeek.from(weekBasedYear, week, config);
  }

  Weekday get weekday =>
      Weekday.fromIndex((daysSinceUnixEpoch.inDays + 3) % Days.perWeek);

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
  CDateTime at(Time time) => CDateTime.from(this, time);

  /// A [Range] of [CDateTime] combining this [Date] and the given time [range].
  Range<CDateTime> atRange(Range<Time> range) =>
      Range(at(range.start), at(range.end));

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
  Date operator +(CalendarDelta duration) {
    final MonthsDays(:months, :days) = duration.toMonthsDays();
    final yearMonthWithMonths = yearMonth + months;
    final dateWithMonths = Date._unchecked(
      yearMonthWithMonths,
      min(day, yearMonthWithMonths.length.inDays),
    );

    return days.inDays == 0
        ? dateWithMonths
        : Date.fromDaysSinceUnixEpoch(dateWithMonths.daysSinceUnixEpoch + days);
  }

  Date operator -(CalendarDelta duration) => this + (-duration);

  /// Returns `this - other` as a number of [Days], i.e., positive if `this` is
  /// later than [other].
  ///
  /// Unlike [since], this doesn't extract months, so it doesn't depend on
  /// which date the calculation starts from.
  Days daysSince(Date other) => daysSinceUnixEpoch - other.daysSinceUnixEpoch;

  /// Returns `other - this` as a number of [Days], i.e., positive if [other] is
  /// later than `this`.
  ///
  /// This is the negation of [daysSince].
  Days daysUntil(Date other) => other.daysSince(this);

  /// Returns a [MonthsDays] so that `this + result == other`.
  ///
  /// [MonthsDays.months] and [MonthsDays.days] are both `>= 0` or both `<= 0`.
  ///
  /// [smallestMonthUnit] is the granularity of [MonthsDays.months]: it's always
  /// a whole multiple of it, truncated towards zero, and the rest is returned
  /// as [MonthsDays.days]. For example, with [MonthUnit.years], Jan 1, 2020 to
  /// Mar 15, 2023 is 36 months and 73 days. Use [Months.split] and [Days.split]
  /// on the result to display it in more units.
  ///
  /// The result is anchored at `this`, so month ends are clamped as in
  /// `this + result`. See [since] for the opposite direction.
  ///
  /// See also [daysSince], which doesn't extract months.
  MonthsDays until(
    Date other, {
    MonthUnit smallestMonthUnit = MonthUnit.months,
  }) {
    var months = other.yearMonth.difference(yearMonth);
    var days = Days(other.day - day);
    if (months.isPositive && days.isNegative) {
      months -= const Months(1);
      days = other.daysSinceUnixEpoch - (this + months).daysSinceUnixEpoch;
    } else if (months.isNegative && days.isPositive) {
      months += const Months(1);
      days -= other.yearMonth.length;
    }

    final truncatedMonths =
        months ~/ smallestMonthUnit.monthsPer * smallestMonthUnit.monthsPer;
    if (truncatedMonths != months) {
      months = truncatedMonths;
      days = other.daysSinceUnixEpoch - (this + months).daysSinceUnixEpoch;
    }
    return MonthsDays(months: months, days: days);
  }

  /// Returns a [MonthsDays] so that `this - result == other`, i.e., the
  /// negation of [until].
  ///
  /// The result is positive if `this` is later than [other]. Because month ends
  /// are clamped starting from `this`, it can differ by a few days from
  /// `other.until(this)`: `mar1.since(jan30)` is 1 month and 2 days in 2023,
  /// whereas `jan30.until(mar1)` is 1 month and 1 day.
  ///
  /// See [until] for [smallestMonthUnit].
  MonthsDays since(
    Date other, {
    MonthUnit smallestMonthUnit = MonthUnit.months,
  }) => -until(other, smallestMonthUnit: smallestMonthUnit);

  /// Calculates the age of someone on [onDate] who was born on `this` date.
  ///
  /// If [onDate] is not provided, the current date in the local zone is used.
  int age({Date? onDate}) {
    onDate ??= Date.todayInLocalZone();

    var age = onDate.year.difference(year);
    if (monthDay > onDate.monthDay) age -= 1;
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

  Date copyWith({YearMonth? yearMonth, Year? year, Month? month, int? day}) {
    assert(yearMonth == null || (year == null && month == null));

    return (yearMonth ?? YearMonth.from(year ?? this.year, month ?? this.month))
        .atDay(day ?? this.day);
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
  int stepsUntil(Date other) => other.daysSince(this).inDays;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Date && yearMonth == other.yearMonth && day == other.day);
  }

  @override
  int get hashCode => Object.hash(yearMonth, day);

  /// Represents a [Date] as an ISO 8601 string, e.g., “2023-04-23”
  static const isoFormat = <DateFormatItem>[
    .year(),
    .literal('-'),
    .month(),
    .literal('-'),
    .day(),
  ];

  /// Represents a [Date] as an ordinal date ISO 8601 string, e.g., “2023-113”.
  static const isoOrdinalFormat = <DateFormatItem>[
    .year(),
    .literal('-'),
    .ordinal(),
  ];

  /// Represents a [Date] as a week date ISO 8601 string, e.g., “2023-W16-7”.
  static const isoWeekDateFormat = <DateFormatItem>[
    .isoYear(),
    .literal('-W'),
    .isoWeek(),
    .literal('-'),
    .weekday(),
  ];

  factory parse(String string, [List<DateFormatItem> items = isoFormat]) =>
      ChronoParser.parse(string, items).toDate();
  static ({Date date, String rest}) parseAndRest(
    String string, [
    List<DateFormatItem> items = isoFormat,
  ]) {
    final result = ChronoParser.parseAndRest(string, items);
    return (date: result.parsed.toDate(), rest: result.rest);
  }

  @override
  String toString([List<DateFormatItem> items = isoFormat]) =>
      ChronoFormatter.format(items, date: this);
}

/// Encodes a [Date] as a string, defaulting to [Date.isoFormat].
class const DateAsStringCodec([
  final List<DateFormatItem> formatItems = Date.isoFormat,
]) extends CodecAndJsonConverter<Date, String> {
  @override
  String encode(Date input) => input.toString(formatItems);
  @override
  Date decode(String encoded) => Date.parse(encoded, formatItems);
}

// Deranged

extension RangeOfDateChrono on Range<Date> {
  /// The [CDateTime]s in these dates.
  Range<CDateTime> get dateTimes => start.atMidnight.rangeUntil(end.atMidnight);

  Days get lengthInDays => end.daysSince(start);
}

extension RangeInclusiveOfDateChrono on RangeInclusive<Date> {
  /// The [CDateTime]s in these dates.
  Range<CDateTime> get dateTimes => exclusive.dateTimes;

  Days get lengthInDays => end.daysSince(start) + const Days(1);
}

/// Encodes a [RangeInclusive] of [Date]s as a string `start/end`.
class const RangeInclusiveOfDateAsStringCodec({
  final List<DateFormatItem> formatItems = Date.isoFormat,
  final String intervalDesignator = '/',
}) extends CodecAndJsonConverter<RangeInclusive<Date>, String> {
  @override
  String encode(RangeInclusive<Date> input) =>
      '${input.start.toString(formatItems)}$intervalDesignator'
      '${input.end.toString(formatItems)}';
  @override
  RangeInclusive<Date> decode(String encoded) {
    final (date: start, :rest) = Date.parseAndRest(encoded, formatItems);

    if (rest.length < intervalDesignator.length) {
      throw const ChronoParseException(.tooShort);
    } else if (!rest.startsWith(intervalDesignator)) {
      throw const ChronoParseException(.invalid);
    }

    final end = Date.parse(
      rest.substring(intervalDesignator.length),
      formatItems,
    );
    return RangeInclusive(start, end);
  }
}
