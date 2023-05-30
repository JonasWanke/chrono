import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../../parser.dart';
import '../../utils.dart';
import '../date.dart';
import '../month/month.dart';
import '../ordinal_date.dart';
import '../period.dart';
import '../weekday.dart';
import '../year.dart';
import 'year_week.dart';

@immutable
final class PlainWeekDate
    with ComparisonOperatorsFromComparable<PlainWeekDate>
    implements Comparable<PlainWeekDate> {
  const PlainWeekDate(this.yearWeek, this.weekday);

  PlainWeekDate.fromDate(PlainDate date) : this(date.yearWeek, date.weekday);

  PlainWeekDate.fromDateTime(DateTime dateTime)
      : this.fromDate(PlainDate.fromDateTime(dateTime));
  PlainWeekDate.todayInLocalZone({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toLocal());
  PlainWeekDate.todayInUtc({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toUtc());

  factory PlainWeekDate.fromJson(String json) =>
      unwrapParserResult(parse(json));
  static Result<PlainWeekDate, FormatException> parse(String value) =>
      Parser.parseWeekDate(value);

  final PlainYearWeek yearWeek;
  final Weekday weekday;

  PlainOrdinalDate get asOrdinalDate {
    // https://en.wikipedia.org/wiki/ISO_week_date#Calculating_an_ordinal_or_month_date_from_a_week_date
    final january4 =
        PlainDate.fromUnchecked(yearWeek.weekBasedYear, PlainMonth.january, 4);

    final rawDayOfYear = Days.perWeek.value * yearWeek.week +
        weekday.number -
        (january4.weekday.number + 3);
    final PlainYear year;
    final int dayOfYear;
    if (rawDayOfYear < 1) {
      year = yearWeek.weekBasedYear - const Years(1);
      dayOfYear = rawDayOfYear + year.lengthInDays.value;
    } else {
      final daysInCurrentYear = yearWeek.weekBasedYear.lengthInDays.value;
      if (rawDayOfYear > daysInCurrentYear) {
        year = yearWeek.weekBasedYear + const Years(1);
        dayOfYear = rawDayOfYear - daysInCurrentYear;
      } else {
        year = yearWeek.weekBasedYear;
        dayOfYear = rawDayOfYear;
      }
    }
    return PlainOrdinalDate.fromUnchecked(year, dayOfYear);
  }

  PlainDate get asDate => asOrdinalDate.asDate;

  bool isTodayInLocalZone({Clock? clockOverride}) =>
      this == PlainWeekDate.todayInLocalZone(clockOverride: clockOverride);
  bool isTodayInUtc({Clock? clockOverride}) =>
      this == PlainWeekDate.todayInUtc(clockOverride: clockOverride);

  PlainWeekDate operator +(FixedDaysPeriod period) =>
      (asDate + period).asWeekDate;
  PlainWeekDate operator -(FixedDaysPeriod period) => this + (-period);

  PlainWeekDate get nextDate {
    return weekday == Weekday.values.last
        ? PlainWeekDate(yearWeek + const Weeks(1), Weekday.values.first)
        : PlainWeekDate(yearWeek, weekday.next);
  }

  PlainWeekDate get previousDate {
    return weekday == Weekday.values.first
        ? PlainWeekDate(yearWeek - const Weeks(1), Weekday.values.last)
        : PlainWeekDate(yearWeek, weekday.previous);
  }

  PlainWeekDate nextOrSame(Weekday weekday) {
    // ignore: avoid_returning_this
    if (weekday == this.weekday) return this;

    return PlainWeekDate(
      weekday < this.weekday ? yearWeek.nextWeek : yearWeek,
      weekday,
    );
  }

  PlainWeekDate previousOrSame(Weekday weekday) {
    // ignore: avoid_returning_this
    if (weekday == this.weekday) return this;

    return PlainWeekDate(
      weekday > this.weekday ? yearWeek.previousWeek : yearWeek,
      weekday,
    );
  }

  PlainWeekDate copyWith({PlainYearWeek? yearWeek, Weekday? weekday}) =>
      PlainWeekDate(yearWeek ?? this.yearWeek, weekday ?? this.weekday);

  @override
  int compareTo(PlainWeekDate other) {
    final result = yearWeek.compareTo(other.yearWeek);
    if (result != 0) return result;

    return weekday.compareTo(other.weekday);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlainWeekDate &&
            yearWeek == other.yearWeek &&
            weekday == other.weekday);
  }

  @override
  int get hashCode => Object.hash(yearWeek, weekday);

  @override
  String toString() => '$yearWeek-${weekday.number}';

  String toJson() => toString();
}
