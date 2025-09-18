import '../date_time/duration.dart';
import '../rounding.dart';
import '../time/duration.dart';
import '../utils.dart';

/// A [CDuration] based on an integer number of days or months.
///
/// This is different to [TimeDelta] because days can be shorter or longer
/// than 24 hours and months have a varying of days.
///
/// See also:
///
/// - [MonthsDuration], which represents an integer number of months or years.
///   - [Months], which represents an integer number of months.
///   - [Years], which represents an integer number of years.
/// - [DaysDuration], which represents an integer number of weeks or days.
///   - [Weeks], which represents an integer number of weeks.
///   - [Days], which represents an integer number of days.
/// - [CompoundCalendarDuration], which combines [Months] and [Days].
/// - [TimeDelta], which covers durations based on a fixed time like seconds.
/// - [CDuration], which is the base class for date and time durations.
abstract class CalendarDuration extends CDuration {
  const CalendarDuration();

  CompoundCalendarDuration get asCompoundCalendarDuration;
  @override
  CompoundDuration get asCompoundDuration =>
      CompoundDuration(monthsAndDays: asCompoundCalendarDuration);

  @override
  CalendarDuration operator -();
  @override
  CalendarDuration operator *(int factor);
  @override
  CalendarDuration operator ~/(int divisor);
  @override
  CalendarDuration operator %(int divisor);
  @override
  CalendarDuration remainder(int divisor);
}

/// [CalendarDuration] subclass that can represent any days-based duration by
/// combining [Months] and [Days].
final class CompoundCalendarDuration extends CalendarDuration {
  CompoundCalendarDuration({
    MonthsDuration months = const Months(0),
    DaysDuration days = const Days(0),
  }) : months = months.asMonths,
       days = days.asDays;

  final Months months;
  final Days days;

  @override
  CompoundCalendarDuration get asCompoundCalendarDuration => this;

  CompoundCalendarDuration operator +(CalendarDuration duration) {
    final CompoundCalendarDuration(:months, :days) =
        duration.asCompoundCalendarDuration;
    return CompoundCalendarDuration(
      months: this.months + months,
      days: this.days + days,
    );
  }

  CompoundCalendarDuration operator -(CalendarDuration duration) =>
      this + (-duration);
  @override
  CompoundCalendarDuration operator -() =>
      CompoundCalendarDuration(months: -months, days: -days);
  @override
  CompoundCalendarDuration operator *(int factor) =>
      CompoundCalendarDuration(months: months * factor, days: days * factor);
  @override
  CompoundCalendarDuration operator ~/(int divisor) {
    return CompoundCalendarDuration(
      months: months ~/ divisor,
      days: days ~/ divisor,
    );
  }

  @override
  CompoundCalendarDuration operator %(int divisor) =>
      CompoundCalendarDuration(months: months % divisor, days: days % divisor);
  @override
  CompoundCalendarDuration remainder(int divisor) {
    return CompoundCalendarDuration(
      months: months.remainder(divisor),
      days: days.remainder(divisor),
    );
  }

  @override
  String toString() => '$months, $days';
}

/// Base class for [Months] and [Years].
abstract class MonthsDuration extends CalendarDuration
    with ComparisonOperatorsFromComparable<MonthsDuration>
    implements Comparable<MonthsDuration> {
  const MonthsDuration();

  Months get asMonths;
  int get inMonths => asMonths.inMonths;

  /// Both are `>= 0` or both are `<= 0`.
  (Years, Months) get splitYearsMonths {
    final asMonths = this.asMonths;
    final years = Years(asMonths.inMonths ~/ Months.perYear);
    return (years, asMonths - years);
  }

  @override
  CompoundCalendarDuration get asCompoundCalendarDuration =>
      CompoundCalendarDuration(months: asMonths);

  bool get isPositive => inMonths > 0;
  bool get isNonPositive => inMonths <= 0;
  bool get isNegative => inMonths < 0;
  bool get isNonNegative => inMonths >= 0;

  @override
  MonthsDuration operator -();
  @override
  MonthsDuration operator *(int factor);
  @override
  MonthsDuration operator ~/(int divisor);
  double dividedByMonthsDuration(MonthsDuration divisor) =>
      inMonths / divisor.inMonths;
  @override
  MonthsDuration operator %(int divisor);
  @override
  MonthsDuration remainder(int divisor);

  MonthsDuration get absolute => isNegative ? -this : this;

  Years roundToYears({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      Years(rounding.round(inMonths / Months.perYear));

  @override
  int compareTo(MonthsDuration other) => inMonths.compareTo(other.inMonths);
}

/// An integer number of months.
final class Months extends MonthsDuration {
  const Months(this.inMonths);
  const Months.fromJson(int json) : this(json);

  /// The number of months in a year.
  static const perYear = 12;

  /// The months in a year.
  static const year = Months(perYear);

  @override
  final int inMonths;

  @override
  Months get asMonths => this;

  Months operator +(MonthsDuration duration) =>
      Months(inMonths + duration.inMonths);
  Months operator -(MonthsDuration duration) =>
      Months(inMonths - duration.inMonths);
  @override
  Months operator -() => Months(-inMonths);
  @override
  Months operator *(int factor) => Months(inMonths * factor);
  @override
  Months operator ~/(int divisor) => Months(inMonths ~/ divisor);
  @override
  Months operator %(int divisor) => Months(inMonths % divisor);
  @override
  Months remainder(int divisor) => Months(inMonths.remainder(divisor));

  @override
  Months get absolute => isNegative ? -this : this;

  @override
  String toString() =>
      inMonths.abs() == 1 ? '$inMonths month' : '$inMonths months';

  int toJson() => inMonths;
}

/// An integer number of years.
final class Years extends MonthsDuration {
  const Years(this.inYears);
  const Years.fromJson(int json) : this(json);

  /// The number of years until the Gregorian calendar cycles repeat: 400.
  static const perGregorianRepeat = 400;

  /// The years until the Gregorian calendar cycles repeat: 400.
  static const gregorianRepeat = Years(perGregorianRepeat);

  final int inYears;

  TimeDelta get asNormalTime => TimeDelta(normalYears: inYears);
  TimeDelta get asNormalLeapTime => TimeDelta(normalLeapYears: inYears);

  /// The days in this many normal (non-leap) years (365 days).
  Days get asNormalDays => Days.normalYear * inYears;

  /// The days in this many leap years (366 days).
  Days get asLeapDays => Days.normalYear * inYears;

  /// The hours in this many normal (non-leap) years (365 days), i.e., years
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  int get asNormalHours => asNormalDays.asNormalHours;

  /// The hours in this many normal leap years (366 days), i.e., years where all
  /// days are exactly 24 hours long (no daylight savings time changes and no
  /// leap seconds).
  int get asNormalLeapHours => asLeapDays.asNormalHours;

  /// The minutes in this many normal (non-leap) years (365 days), i.e., years
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  int get asNormalMinutes => asNormalDays.asNormalMinutes;

  /// The minutes in this many normal leap years (366 days), i.e., years where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  int get asNormalLeapMinutes => asLeapDays.asNormalMinutes;

  /// The seconds in this many normal (non-leap) years (365 days), i.e., years
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  int get asNormalSeconds => asNormalDays.asNormalSeconds;

  /// The seconds in this many normal leap years (366 days), i.e., years where
  /// all days are exactly 24 hours long (no daylight savings time changes and
  /// no leap seconds).
  int get asNormalLeapSeconds => asLeapDays.asNormalSeconds;

  /// The milliseconds in this many normal (non-leap) years (365 days), i.e.,
  /// years where all days are exactly 24 hours long (no daylight savings time
  /// changes and no leap seconds).
  int get asNormalMillis => asNormalDays.asNormalMillis;

  /// The milliseconds in this many normal leap years (366 days), i.e., years
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  int get asNormalLeapMillis => asLeapDays.asNormalMillis;

  /// The microseconds in this many normal (non-leap) years (365 days), i.e.,
  /// years where all days are exactly 24 hours long (no daylight savings time
  /// changes and no leap seconds).
  int get asNormalMicros => asNormalDays.asNormalMicros;

  /// The microseconds in this many normal leap years (366 days), i.e., years
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  int get asNormalLeapMicros => asLeapDays.asNormalMicros;

  /// The nanoseconds in this many normal (non-leap) years (365 days), i.e.,
  /// years where all days are exactly 24 hours long (no daylight savings time
  /// changes and no leap seconds).
  int get asNormalNanos => asNormalDays.asNormalNanos;

  /// The nanoseconds in this many normal leap years (366 days), i.e., years
  /// where all days are exactly 24 hours long (no daylight savings time changes
  /// and no leap seconds).
  int get asNormalLeapNanos => asLeapDays.asNormalNanos;

  @override
  (Years, Months) get splitYearsMonths => (this, const Months(0));
  @override
  Months get asMonths => Months.year * inYears;

  Years operator +(Years duration) => Years(inYears + duration.inYears);
  Years operator -(Years duration) => Years(inYears - duration.inYears);
  @override
  Years operator -() => Years(-inYears);
  @override
  Years operator *(int factor) => Years(inYears * factor);
  @override
  Years operator ~/(int divisor) => Years(inYears ~/ divisor);
  double dividedByYears(Years divisor) => inYears / divisor.inYears;
  @override
  Years operator %(int divisor) => Years(inYears % divisor);
  @override
  Years remainder(int divisor) => Years(inYears.remainder(divisor));

  @override
  Years get absolute => isNegative ? -this : this;

  @override
  String toString() => inYears.abs() == 1 ? '$inYears year' : '$inYears years';

  int toJson() => inYears;
}

/// Base class for [Days] and [Weeks].
abstract class DaysDuration extends CalendarDuration
    with ComparisonOperatorsFromComparable<DaysDuration>
    implements Comparable<DaysDuration> {
  const DaysDuration();

  Days get asDays;
  int get inDays => asDays.inDays;
  TimeDelta get asTime => TimeDelta(normalDays: inDays);
  int get asNormalHours => TimeDelta.hoursPerNormalDay * inDays;
  int get asNormalMinutes => TimeDelta.minutesPerNormalDay * inDays;
  int get asNormalSeconds => TimeDelta.secondsPerNormalDay * inDays;
  int get asNormalMillis => TimeDelta.millisPerNormalDay * inDays;
  int get asNormalMicros => TimeDelta.microsPerNormalDay * inDays;
  int get asNormalNanos => TimeDelta.nanosPerNormalDay * inDays;

  /// Both are `>= 0` or both are `<= 0`.
  (Weeks, Days) get splitWeeksDays {
    final asDays = this.asDays;
    final weeks = Weeks(asDays.inDays ~/ Days.perWeek);
    return (weeks, asDays - weeks);
  }

  @override
  CompoundCalendarDuration get asCompoundCalendarDuration =>
      CompoundCalendarDuration(days: asDays);

  bool get isPositive => inDays > 0;
  bool get isNonPositive => inDays <= 0;
  bool get isNegative => inDays < 0;
  bool get isNonNegative => inDays >= 0;

  @override
  DaysDuration operator -();
  @override
  DaysDuration operator *(int factor);
  @override
  DaysDuration operator ~/(int divisor);
  double dividedByDaysDuration(DaysDuration divisor) => inDays / divisor.inDays;
  @override
  DaysDuration operator %(int divisor);
  @override
  DaysDuration remainder(int divisor);

  DaysDuration get absolute => isNegative ? -this : this;

  Weeks roundToWeeks({Rounding rounding = Rounding.nearestAwayFromZero}) =>
      Weeks(rounding.round(inDays / Days.perWeek));

  @override
  int compareTo(DaysDuration other) => inDays.compareTo(other.inDays);
}

/// An integer number of days.
final class Days extends DaysDuration {
  const Days(this.inDays);
  const Days.fromJson(int json) : this(json);

  /// The number of days in a week.
  static const perWeek = 7;

  /// The days in a week.
  static const week = Days(perWeek);

  /// The number of days in a normal (non-leap) year.
  static const perNormalYear = 365;

  /// The days in a normal (non-leap) year.
  static const normalYear = Days(perNormalYear);

  /// The number of days in a leap year.
  static const perLeapYear = 366;

  /// The days in a leap year.
  static const leapYear = Days(perLeapYear);

  @override
  final int inDays;

  @override
  Days get asDays => this;

  Days operator +(DaysDuration duration) =>
      Days(inDays + duration.asDays.inDays);
  Days operator -(DaysDuration duration) =>
      Days(inDays - duration.asDays.inDays);
  @override
  Days operator -() => Days(-inDays);
  @override
  Days operator *(int factor) => Days(inDays * factor);
  @override
  Days operator ~/(int divisor) => Days(inDays ~/ divisor);
  @override
  Days operator %(int divisor) => Days(inDays % divisor);
  @override
  Days remainder(int divisor) => Days(inDays.remainder(divisor));

  @override
  Days get absolute => isNegative ? -this : this;

  @override
  String toString() => inDays.abs() == 1 ? '$inDays day' : '$inDays days';

  int toJson() => inDays;
}

/// An integer number of weeks.
final class Weeks extends DaysDuration {
  const Weeks(this.inWeeks);
  const Weeks.fromJson(int json) : this(json);

  final int inWeeks;

  @override
  Days get asDays => Days.week * inWeeks;

  Weeks operator +(Weeks duration) => Weeks(inWeeks + duration.inWeeks);
  Weeks operator -(Weeks duration) => Weeks(inWeeks - duration.inWeeks);
  @override
  Weeks operator -() => Weeks(-inWeeks);
  @override
  Weeks operator *(int factor) => Weeks(inWeeks * factor);
  @override
  Weeks operator ~/(int divisor) => Weeks(inWeeks ~/ divisor);
  double dividedByWeeks(Weeks divisor) => inWeeks / divisor.inWeeks;
  @override
  Weeks operator %(int divisor) => Weeks(inWeeks % divisor);
  @override
  Weeks remainder(int divisor) => Weeks(inWeeks.remainder(divisor));

  @override
  Weeks get absolute => isNegative ? -this : this;

  @override
  String toString() => inWeeks.abs() == 1 ? '$inWeeks week' : '$inWeeks weeks';

  int toJson() => inWeeks;
}
