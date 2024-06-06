import '../date_time/duration.dart';
import '../rounding.dart';
import '../time/duration.dart';
import '../utils.dart';

/// A [Duration] based on an integer number of days or months.
///
/// This is different to [TimeDuration] because days can be shorter or longer
/// than 24 hours and months have a varying of days.
///
/// See also:
///
/// - [MonthsDuration], which represents an integer number of months or years.
///   - [Months], which represents an integer number of months.
///   - [Years], which represents an integer number of years.
/// - [FixedDaysDuration], which represents an integer number of weeks or days.
///   - [Weeks], which represents an integer number of weeks.
///   - [Days], which represents an integer number of days.
/// - [CompoundDaysDuration], which combines [Months] and [Days].
/// - [TimeDuration], which covers durations based on a fixed time like seconds.
/// - [Duration], which is the base class for date and time durations.
abstract class DaysDuration extends Duration {
  const DaysDuration();

  CompoundDaysDuration get asCompoundDaysDuration;
  @override
  CompoundDuration get asCompoundDuration =>
      CompoundDuration(monthsAndDays: asCompoundDaysDuration);

  @override
  DaysDuration operator -();
  @override
  DaysDuration operator *(int factor);
  @override
  DaysDuration operator ~/(int divisor);
  @override
  DaysDuration operator %(int divisor);
  @override
  DaysDuration remainder(int divisor);
}

/// [DaysDuration] subclass that can represent any days-based duration by
/// combining [Months] and [Days].
final class CompoundDaysDuration extends DaysDuration {
  CompoundDaysDuration({
    MonthsDuration months = const Months(0),
    FixedDaysDuration days = const Days(0),
  })  : months = months.asMonths,
        days = days.asDays;

  final Months months;
  final Days days;

  @override
  CompoundDaysDuration get asCompoundDaysDuration => this;

  CompoundDaysDuration operator +(DaysDuration duration) {
    final CompoundDaysDuration(:months, :days) =
        duration.asCompoundDaysDuration;
    return CompoundDaysDuration(
      months: this.months + months,
      days: this.days + days,
    );
  }

  CompoundDaysDuration operator -(DaysDuration duration) => this + (-duration);
  @override
  CompoundDaysDuration operator -() =>
      CompoundDaysDuration(months: -months, days: -days);
  @override
  CompoundDaysDuration operator *(int factor) =>
      CompoundDaysDuration(months: months * factor, days: days * factor);
  @override
  CompoundDaysDuration operator ~/(int divisor) =>
      CompoundDaysDuration(months: months ~/ divisor, days: days ~/ divisor);
  @override
  CompoundDaysDuration operator %(int divisor) =>
      CompoundDaysDuration(months: months % divisor, days: days % divisor);
  @override
  CompoundDaysDuration remainder(int divisor) {
    return CompoundDaysDuration(
      months: months.remainder(divisor),
      days: days.remainder(divisor),
    );
  }

  @override
  String toString() => '$months, $days';
}

/// Base class for [Months] and [Years].
abstract class MonthsDuration extends DaysDuration
    with ComparisonOperatorsFromComparable<MonthsDuration>
    implements Comparable<MonthsDuration> {
  const MonthsDuration();

  Months get asMonths;
  int get inMonths => asMonths.inMonths;

  /// Both are `>= 0` or both are `<= 0`.
  (Years, Months) get asYearsAndMonths {
    final thisMonths = asMonths;
    final years = Years(thisMonths.inMonths ~/ Months.perYear);
    final months = thisMonths - years.asMonths;
    return (years, months);
  }

  @override
  CompoundDaysDuration get asCompoundDaysDuration =>
      CompoundDaysDuration(months: asMonths);

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

  Years roundToYears({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
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

  @override
  (Years, Months) get asYearsAndMonths => (this, const Months(0));
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
abstract class FixedDaysDuration extends DaysDuration
    with ComparisonOperatorsFromComparable<FixedDaysDuration>
    implements Comparable<FixedDaysDuration> {
  const FixedDaysDuration();

  Days get asDays;
  int get inDays => asDays.inDays;
  Hours get asNormalHours => Hours.normalDay * inDays;
  Minutes get asNormalMinutes => asNormalHours.asMinutes;
  Seconds get asNormalSeconds => asNormalHours.asSeconds;
  Milliseconds get asNormalMilliseconds => asNormalHours.asMilliseconds;
  Microseconds get asNormalMicroseconds => asNormalHours.asMicroseconds;
  Nanoseconds get asNormalNanoseconds => asNormalHours.asNanoseconds;

  /// Both are `>= 0` or both are `<= 0`.
  (Weeks, Days) get asWeeksAndDays {
    final thisDays = asDays;
    final weeks = Weeks(thisDays.inDays ~/ Days.perWeek);
    final days = thisDays - weeks.asDays;
    return (weeks, days);
  }

  @override
  CompoundDaysDuration get asCompoundDaysDuration =>
      CompoundDaysDuration(days: asDays);

  bool get isPositive => inDays > 0;
  bool get isNonPositive => inDays <= 0;
  bool get isNegative => inDays < 0;
  bool get isNonNegative => inDays >= 0;

  @override
  FixedDaysDuration operator -();
  @override
  FixedDaysDuration operator *(int factor);
  @override
  FixedDaysDuration operator ~/(int divisor);
  double dividedByFixedDaysDuration(FixedDaysDuration divisor) =>
      inDays / divisor.inDays;
  @override
  FixedDaysDuration operator %(int divisor);
  @override
  FixedDaysDuration remainder(int divisor);

  FixedDaysDuration get absolute => isNegative ? -this : this;

  Weeks roundToWeeks({
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      Weeks(rounding.round(inDays / Days.perWeek));

  @override
  int compareTo(FixedDaysDuration other) => inDays.compareTo(other.inDays);
}

/// An integer number of days.
final class Days extends FixedDaysDuration {
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

  Days operator +(FixedDaysDuration duration) =>
      Days(inDays + duration.asDays.inDays);
  Days operator -(FixedDaysDuration duration) =>
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
final class Weeks extends FixedDaysDuration {
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
