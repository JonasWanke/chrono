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
import 'time/duration.dart';
import 'time/time.dart';

extension DateTimeChronoExtension on DateTime {
  CDateTime get asChronoDateTime => CDateTime.fromCore(this);
  Date get asChronoDate => Date.fromCore(this);
  Year get asChronoYear => Year(year);
  Month get asChronoMonth => Month.fromNumber(month).unwrap();
  YearMonth get asChronoYearMonth => YearMonth(asChronoYear, asChronoMonth);
  MonthDay get asChronoMonthDay => MonthDay.from(asChronoMonth, day).unwrap();
  IsoYearWeek get asChronoIsoYearWeek => asChronoDate.isoYearWeek;
  YearWeek asChronoYearWeek(WeekConfig config) => asChronoDate.yearWeek(config);
  Weekday get asChronoWeekday => Weekday.fromNumber(weekday).unwrap();
  Time get asChronoTime => asChronoDateTime.time;
}

extension StopwatchChronoExtension on Stopwatch {
  Microseconds get elapsedChrono => Microseconds(elapsedMicroseconds);
}
