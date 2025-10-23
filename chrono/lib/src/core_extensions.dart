import 'date/date.dart';
import 'date/month/month.dart';
import 'date/month/month_day.dart';
import 'date/month/year_month.dart';
import 'date/week/iso_year_week.dart';
import 'date/week/week_config.dart';
import 'date/week/year_week.dart';
import 'date/weekday.dart';
import 'date/year.dart';
import 'date_time/date_time.dart';
import 'instant.dart';
import 'time/duration.dart';
import 'time/time.dart';

extension DateTimeChronoExtension on DateTime {
  Instant get asChronoInstant => Instant.fromCore(this);
  CDateTime get asChronoDateTime => CDateTime.fromCore(this);
  Date get asChronoDate => Date.fromCore(this);
  Year get asChronoYear => Year(year);
  Month get asChronoMonth => Month.fromNumber(month);
  YearMonth get asChronoYearMonth => YearMonth(asChronoYear, asChronoMonth);
  MonthDay get asChronoMonthDay => MonthDay.from(asChronoMonth, day);
  IsoYearWeek get asChronoIsoYearWeek => asChronoDate.isoYearWeek;
  YearWeek asChronoYearWeek(WeekConfig config) => asChronoDate.yearWeek(config);
  Weekday get asChronoWeekday => Weekday.fromNumber(weekday);
  Time get asChronoTime => asChronoDateTime.time;
}

extension DurationChronoExtension on Duration {
  TimeDelta get asChronoTimeDelta => TimeDelta.fromCore(this);
}

extension StopwatchChronoExtension on Stopwatch {
  TimeDelta get elapsedChrono => TimeDelta(micros: elapsedMicroseconds);
}
