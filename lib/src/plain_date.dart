import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
import 'plain_date_time.dart';
import 'plain_month.dart';
import 'plain_time.dart';
import 'plain_year.dart';
import 'plain_year_month.dart';
import 'utils.dart';

@immutable
final class PlainDate
    with ComparisonOperatorsFromComparable<PlainDate>
    implements Comparable<PlainDate> {
  const PlainDate.fromYearMonthAndDayUnchecked(this.yearMonth, this.day);
  factory PlainDate.fromThrowing(
    PlainYear year, [
    PlainMonth month = PlainMonth.january,
    int day = 1,
  ]) =>
      from(year, month, day).unwrap();
  factory PlainDate.fromYearMonthAndDayThrowing(
    PlainYearMonth yearMonth,
    int day,
  ) =>
      fromYearMonthAndDay(yearMonth, day).unwrap();
  factory PlainDate.fromDaysSinceUnixEpoch(int daysSinceUnixEpoch) {
    // https://howardhinnant.github.io/date_algorithms.html#civil_from_days
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

    return PlainDate.fromYearMonthAndDayUnchecked(
      PlainYearMonth.from(
        PlainYear.from(year),
        PlainMonth.fromNumberUnchecked(month),
      ),
      day,
    );
  }

  PlainDate.fromDateTime(DateTime dateTime)
      : this.fromYearMonthAndDayUnchecked(
          PlainYearMonth.fromDateTime(dateTime),
          dateTime.day,
        );
  PlainDate.todayInLocalZone({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toLocal());
  PlainDate.todayInUtc({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toUtc());

  factory PlainDate.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<PlainDate, FormatException> parse(String value) =>
      Parser.parseDate(value);

  static Result<PlainDate, String> from(
    PlainYear year, [
    PlainMonth month = PlainMonth.january,
    int day = 1,
  ]) =>
      fromYearMonthAndDay(PlainYearMonth.from(year, month), day);
  static Result<PlainDate, String> fromYearMonthAndDay(
    PlainYearMonth yearMonth,
    int day,
  ) {
    if (day < 0 || day > yearMonth.numberOfDays) {
      return Err('Invalid day for $yearMonth: $day');
    }
    return Ok(PlainDate.fromYearMonthAndDayUnchecked(yearMonth, day));
  }

  final PlainYearMonth yearMonth;
  PlainYear get year => yearMonth.year;
  PlainMonth get month => yearMonth.month;
  final int day;

  // TODO: week and day of week

  int get daysSinceUnixEpoch {
    // https://howardhinnant.github.io/date_algorithms.html#days_from_civil
    final (year, month) = this.month <= PlainMonth.february
        ? (this.year.value - 1, this.month.number + 9)
        : (this.year.value, this.month.number - 3);

    final era = (year >= 0 ? year : year - 399) ~/ 400;

    final yearOfEra = year - era * 400;
    assert(0 <= yearOfEra && yearOfEra <= 399);

    final dayOfYear = (month * 153 + 2) ~/ 5 + day - 1;
    assert(0 <= dayOfYear && dayOfYear <= 365);

    final dayOfEra =
        yearOfEra * 365 + yearOfEra ~/ 4 - yearOfEra ~/ 100 + dayOfYear;
    assert(0 <= dayOfEra && dayOfEra <= 146096);

    return era * 146097 + dayOfEra - 719468;
  }

  bool isTodayInLocalZone({Clock? clockOverride}) =>
      this == PlainDate.todayInLocalZone(clockOverride: clockOverride);
  bool isTodayInUtc({Clock? clockOverride}) =>
      this == PlainDate.todayInUtc(clockOverride: clockOverride);

  PlainDateTime at(PlainTime time) => PlainDateTime(this, time);

  Result<PlainDate, String> copyWith({
    PlainYearMonth? yearMonth,
    PlainYear? year,
    PlainMonth? month,
    int? day,
  }) {
    assert(yearMonth == null || (year == null && month == null));

    return PlainDate.fromYearMonthAndDay(
      yearMonth ?? PlainYearMonth.from(year ?? this.year, month ?? this.month),
      day ?? this.day,
    );
  }

  @override
  int compareTo(PlainDate other) {
    final result = yearMonth.compareTo(other.yearMonth);
    if (result != 0) return result;

    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlainDate &&
            yearMonth == other.yearMonth &&
            day == other.day);
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
