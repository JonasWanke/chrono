import 'dart:core' as core;

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

extension CoreDateTimeChronoExtension on core.DateTime {
  DateTime get chronoDateTime => DateTime.fromCore(this);
  Date get chronoDate => Date.fromCore(this);
  Year get chronoYear => Year(year);
  Month get chronoMonth => Month.fromNumber(month).unwrap();
  YearMonth get chronoYearMonth => YearMonth(chronoYear, chronoMonth);
  MonthDay get chronoMonthDay => MonthDay.from(chronoMonth, day).unwrap();
  IsoYearWeek get chronoIsoYearWeek => chronoDate.isoYearWeek;
  YearWeek chronoYearWeek(WeekConfig config) => chronoDate.yearWeek(config);
  Weekday get chronoWeekday => Weekday.fromNumber(weekday).unwrap();
  Time get chronoTime => chronoDateTime.time;
}

extension StopwatchChronoExtension on core.Stopwatch {
  Microseconds get elapsedChrono => Microseconds(elapsedMicroseconds);
}
