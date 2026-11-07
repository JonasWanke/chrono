import 'date/date.dart';
import 'date/month/month.dart';
import 'date/month/month_day.dart';
import 'date/month/year_month.dart';
import 'date/week/week_config.dart';
import 'date/week/year_week.dart';
import 'date/weekday.dart';
import 'date/year.dart';
import 'date_time/date_time.dart';
import 'instant.dart';
import 'time/duration.dart';
import 'time/time.dart';

extension DateTimeChronoExtension on DateTime {
  Instant get chronoInstant => Instant.fromCore(this);
  CDateTime get chronoDateTime => CDateTime.fromCore(this);
  Date get chronoDate => Date.fromCore(this);
  Year get chronoYear => Year(year);
  Month get chronoMonth => Month.fromNumber(month);
  YearMonth get chronoYearMonth => YearMonth.from(chronoYear, chronoMonth);
  MonthDay get chronoMonthDay => MonthDay.from(chronoMonth, day);
  YearWeek chronoYearWeek(WeekConfig config) => chronoDate.yearWeek(config);
  Weekday get chronoWeekday => Weekday.fromNumber(weekday);
  Time get chronoTime => chronoDateTime.time;
}

extension DurationChronoExtension on Duration {
  TimeDelta toChronoTimeDelta() => TimeDelta.fromCore(this);
}

extension StopwatchChronoExtension on Stopwatch {
  TimeDelta get chronoElapsed => TimeDelta(micros: elapsedMicroseconds);
}
