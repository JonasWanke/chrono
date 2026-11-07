import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';

import '../codec.dart';
import '../date_time/date_time.dart';
import '../parser.dart';
import '../utils.dart';
import 'date.dart';
import 'duration.dart';
import 'era.dart';
import 'month/month.dart';
import 'month/year_month.dart';
import 'weekday.dart';
import 'week/week_config.dart';
import 'week/year_week.dart';

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
final class const Year(final int number)
    with ComparisonOperatorsFromComparable<Year>, StepUnlimited<Year>
    implements Comparable<Year> {
  /// The UNIX epoch: 1970.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static const unixEpoch = Year(1970);

  /// The number of years until the Gregorian calendar cycles repeat: 400.
  static const perGregorianRepeat = 400;

  factory currentInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).year;
  factory currentInUtc({Clock? clock}) => Date.todayInUtc(clock: clock).year;

  Era get era => number >= 1 ? Era.common : Era.beforeCommon;

  /// The year number in the [era].
  ///
  /// For example, the year number of `Year(2024)` is `2024`, the year number of
  /// `Year(-1)` is `2`.
  int get eraYear {
    return switch (era) {
      Era.common => number,
      Era.beforeCommon => -number + 1,
    };
  }

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

  /// The [YearMonth] of the given [month] in this year.
  YearMonth atMonth(Month month) => YearMonth.from(this, month);

  /// The [Date] with the given one-based ordinal day of this year, e.g., the
  /// 113th day of 2023.
  ///
  /// Throws a [RangeError] if [dayOfYear] is not in `1..length.inDays`.
  Date atOrdinalDay(int dayOfYear) {
    RangeError.checkValueInInterval(
      dayOfYear,
      1,
      length.inDays,
      'dayOfYear',
      'Invalid day of year for year $this.',
    );

    int firstDayOfYear(Month month) {
      final firstDayOfYearList = isCommonYear
          ? const [1, 32, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]
          : const [1, 32, 61, 92, 122, 153, 183, 214, 245, 275, 306, 336];
      return firstDayOfYearList[month.index];
    }

    final rawMonth = atMonth(Month.fromIndex((dayOfYear - 1) ~/ 31));
    final monthEnd =
        firstDayOfYear(rawMonth.month) + rawMonth.length.inDays - 1;
    final month = dayOfYear > monthEnd ? rawMonth.next : rawMonth;

    return month.atDay(dayOfYear - firstDayOfYear(month.month) + 1);
  }

  /// The [Date] with the given [weekNumber] (see [Date.weekNumberStartingOn])
  /// and [weekday] in this calendar year, e.g., Thursday in week 3.
  ///
  /// Week 1 starts at the first [firstDay] of the year, and days before it are
  /// in week 0.
  ///
  /// Throws a [RangeError] if the date isn't in this year.
  Date atWeekNumber(
    int weekNumber,
    Weekday weekday, {
    required Weekday firstDay,
  }) {
    final january1 = atMonth(Month.january).atDay(1);
    final firstWeekStart =
        january1.weekday.untilNextOrSame(firstDay).inDays + 1;
    final ordinal =
        firstWeekStart +
        (weekNumber - 1) * Days.perWeek +
        weekday.indexFrom(firstDay);
    return atOrdinalDay(ordinal);
  }

  /// The [YearWeek] with the given one-based [week] number in this
  /// week-based year.
  ///
  /// Throws a [RangeError] if [week] is not in `1..numberOfWeeks(config)`.
  YearWeek atWeek(int week, WeekConfig config) =>
      YearWeek.from(this, week, config);

  /// The [YearMonth]s of this year.
  RangeInclusive<YearMonth> get months => YearMonth.from(
    this,
    Month.january,
  ).rangeTo(YearMonth.from(this, Month.december));

  int numberOfWeeks(WeekConfig config) {
    return 1 +
        lastDayOfWeekBasedYear(config)
                .daysSince(firstDayOfWeekBasedYear(config))
                .inDays ~/
            Days.perWeek;
  }

  Date firstDayOfWeekBasedYear(WeekConfig config) {
    final weekDate =
        dates.start +
        Days.week -
        Days(dates.start.weekday.numberFrom(config.firstDay) - 1);
    assert(weekDate.weekday == config.firstDay);

    final reference = months.start.atDay(config.minDaysInFirstWeek);
    return weekDate > reference ? weekDate - Days.week : weekDate;
  }

  Date lastDayOfWeekBasedYear(WeekConfig config) =>
      next.firstDayOfWeekBasedYear(config) - const Days(1);

  /// The [YearWeek]s in this year.
  RangeInclusive<YearWeek> weeks(WeekConfig config) {
    return RangeInclusive(
      YearWeek.from(this, 1, config),
      YearWeek.from(this, numberOfWeeks(config), config),
    );
  }

  /// The [Date]s in this year.
  RangeInclusive<Date> get dates => months.dates;

  /// The [CDateTime]s in this year.
  Range<CDateTime> get dateTimes => dates.dateTimes;

  Year operator +(int years) => Year(number + years);
  Year operator -(int years) => Year(number - years);

  /// Returns `this - other` as a number of years.
  int difference(Year other) => number - other.number;

  @override
  int compareTo(Year other) => number.compareTo(other.number);

  @override
  Year stepBy(int count) => this + count;
  @override
  int stepsUntil(Year other) => other.difference(this);

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

extension RangeOfYearChrono on Range<Year> {
  /// The [YearMonth]s in these years.
  RangeInclusive<YearMonth> get months => inclusive.months;

  /// The [YearWeek]s in these years.
  RangeInclusive<YearWeek> weeks(WeekConfig config) => inclusive.weeks(config);

  /// The [Date]s in these years.
  RangeInclusive<Date> get dates => inclusive.dates;

  /// The [DateTime]s in these years.
  Range<CDateTime> get dateTimes =>
      start.dateTimes.start.rangeUntil(end.dates.start.dateTimes.start);
}

extension RangeInclusiveOfYearChrono on RangeInclusive<Year> {
  /// The [YearMonth]s in these years.
  RangeInclusive<YearMonth> get months =>
      start.months.start.rangeTo(end.months.end);

  /// The [YearWeek]s in these years.
  RangeInclusive<YearWeek> weeks(WeekConfig config) =>
      start.weeks(config).start.rangeTo(end.weeks(config).end);

  /// The [Date]s in these years.
  RangeInclusive<Date> get dates => months.dates;

  /// The [DateTime]s in these years.
  Range<CDateTime> get dateTimes => exclusive.dateTimes;
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
/// - [YearAsIntCodec], which encodes a year as an integer.
class const YearAsIsoStringCodec() extends CodecAndJsonConverter<Year, String> {
  @override
  String encode(Year input) => input.toString();
  @override
  Year decode(String encoded) => Parser.parseYear(encoded);
}

/// Encodes a [Year] as an integer.
///
/// See also:
/// - [YearAsIsoStringCodec], which encodes a year as a string.
@immutable
class const YearAsIntCodec() extends CodecAndJsonConverter<Year, int> {
  @override
  int encode(Year input) => input.number;
  @override
  Year decode(int encoded) => Year(encoded);
}
