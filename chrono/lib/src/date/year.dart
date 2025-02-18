import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../codec.dart';
import '../date_time/date_time.dart';
import '../parser.dart';
import '../utils.dart';
import 'date.dart';
import 'duration.dart';
import 'era.dart';
import 'month/month.dart';
import 'month/year_month.dart';
import 'week/iso_year_week.dart';
import 'week/week_config.dart';
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
    implements Comparable<Year>, Step<Year> {
  const Year(this.number);

  /// The UNIX epoch: 1970.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static const unixEpoch = Year(1970);

  factory Year.currentInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).year;
  factory Year.currentInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).year;

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

  /// The [YearMonth]s of this year.
  RangeInclusive<YearMonth> get months =>
      YearMonth(this, Month.january).rangeTo(YearMonth(this, Month.december));

  int get numberOfIsoWeeks {
    // https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
    final isLongWeek = dates.endInclusive.weekday == Weekday.thursday ||
        previous.dates.endInclusive.weekday == Weekday.wednesday;
    return isLongWeek ? 53 : 52;
  }

  /// The [IsoYearWeek]s in this year.
  RangeInclusive<IsoYearWeek> get isoWeeks {
    return RangeInclusive(
      IsoYearWeek.from(this, 1).unwrap(),
      IsoYearWeek.from(this, numberOfIsoWeeks).unwrap(),
    );
  }

  int numberOfWeeks(WeekConfig config) {
    return 1 +
        lastDayOfWeekBasedYear(config)
                .differenceInDays(firstDayOfWeekBasedYear(config))
                .inDays ~/
            Days.perWeek;
  }

  Date firstDayOfWeekBasedYear(WeekConfig config) {
    final weekDate = dates.start +
        Days.week -
        Days(dates.start.weekday.number(firstDayOfWeek: config.firstDay) - 1);
    assert(weekDate.weekday == config.firstDay);

    final reference =
        Date.fromYearMonthAndDay(months.start, config.minDaysInFirstWeek)
            .unwrap();
    return weekDate > reference ? weekDate - const Weeks(1) : weekDate;
  }

  Date lastDayOfWeekBasedYear(WeekConfig config) =>
      next.firstDayOfWeekBasedYear(config) - const Days(1);

  /// The [YearWeek]s in this year.
  RangeInclusive<YearWeek> weeks(WeekConfig config) {
    return RangeInclusive(
      YearWeek.from(this, 1, config).unwrap(),
      YearWeek.from(this, numberOfWeeks(config), config).unwrap(),
    );
  }

  /// The [Date]s in this year.
  RangeInclusive<Date> get dates => months.dates;

  /// The [CDateTime]s in this year.
  Range<CDateTime> get dateTimes => dates.dateTimes;

  Year operator +(Years duration) => Year(number + duration.inYears);
  Year operator -(Years duration) => Year(number - duration.inYears);

  /// The year after this one.
  Year get next => this + const Years(1);

  /// The year before this one.
  Year get previous => this - const Years(1);

  /// Returns `this - other` as a number of [Years].
  Years difference(Year other) => Years(number - other.number);

  @override
  int compareTo(Year other) => number.compareTo(other.number);

  @override
  Year stepBy(int count) => this + Years(count);
  @override
  int stepsUntil(Year other) => other.difference(this).inYears;

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

  /// The [IsoYearWeek]s in these years.
  RangeInclusive<IsoYearWeek> get isoWeeks => inclusive.isoWeeks;

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
      start.months.start.rangeTo(endInclusive.months.endInclusive);

  /// The [IsoYearWeek]s in these years.
  RangeInclusive<IsoYearWeek> get isoWeeks =>
      start.isoWeeks.start.rangeTo(endInclusive.isoWeeks.endInclusive);

  /// The [YearWeek]s in these years.
  RangeInclusive<YearWeek> weeks(WeekConfig config) => start
      .weeks(config)
      .start
      .rangeTo(endInclusive.weeks(config).endInclusive);

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
class YearAsIsoStringCodec extends CodecWithParserResult<Year, String> {
  const YearAsIsoStringCodec();

  @override
  String encode(Year input) => input.toString();
  @override
  Result<Year, FormatException> decodeAsResult(String encoded) =>
      Parser.parseYear(encoded);
}

/// Encodes a [Year] as an integer.
///
/// See also:
/// - [YearAsIsoStringCodec], which encodes a year as a string.
@immutable
class YearAsIntCodec extends CodecAndJsonConverter<Year, int> {
  const YearAsIntCodec();

  @override
  int encode(Year input) => input.number;
  @override
  Year decode(int encoded) => Year(encoded);
}
