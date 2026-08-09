import 'package:meta/meta.dart';

import '../../chrono.dart' show TimeDelta;
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
/// - [Days], which represents an integer number of days.
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
    this.days = const Days(0),
  }) : months = months.asMonths;

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
  Days get asLeapDays => Days.leapYear * inYears;

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

/// A unit of the day family: A length that is an exact, context-free multiple
/// of a day.
///
/// Members of this enum are units rather than types precisely because they are
/// exact multiples of each other – a week is *always* seven days.
enum DayUnit {
  days(1),
  weeks(Days.perWeek),
  fortnights(2 * Days.perWeek);

  const DayUnit(this.daysPer);

  /// The number of days in one of this unit.
  final int daysPer;

  /// How many of `this` fit in one [larger], e.g.,
  /// `DayUnit.days.per(.weeks) == 7`.
  int per(DayUnit larger) {
    assert(larger.daysPer >= daysPer, 'Argument must be the larger unit.');
    return larger.daysPer ~/ daysPer;
  }
}

/// The result of [Days.split]: One value per requested [DayUnit].
///
/// Reading a unit that wasn't requested throws instead of returning zero, since
/// that is almost certainly a bug and zero would hide it. Use [maybe] or [has]
/// when the requested set isn't statically known.
///
/// All components share the sign of the duration they were split from.
@immutable
final class DayParts extends ChronoParts<DayUnit> {
  const DayParts._(super.values);

  @override
  List<DayUnit> get allUnitsOrdered => DayUnit.values;

  int get days => get(.days);
  int get weeks => get(.weeks);
  int get fortnights => get(.fortnights);
}

/// An integer number of days.
///
/// This is different to [TimeDelta] because days can be shorter or longer than
/// 24 hours due to daylight savings time changes.
final class Days extends CalendarDuration
    with ComparisonOperatorsFromComparable<Days>
    implements Comparable<Days> {
  const Days(this.inDays);
  const Days.fromJson(int json) : this(json);

  /// The days in [weeks] weeks.
  const Days.fromWeeks(int weeks) : inDays = weeks * perWeek;

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

  final int inDays;

  TimeDelta get asTime => TimeDelta(normalDays: inDays);
  int get asNormalHours => TimeDelta.hoursPerNormalDay * inDays;
  int get asNormalMinutes => TimeDelta.minutesPerNormalDay * inDays;
  int get asNormalSeconds => TimeDelta.secondsPerNormalDay * inDays;
  int get asNormalMillis => TimeDelta.millisPerNormalDay * inDays;
  int get asNormalMicros => TimeDelta.microsPerNormalDay * inDays;
  int get asNormalNanos => TimeDelta.nanosPerNormalDay * inDays;

  @override
  CompoundCalendarDuration get asCompoundCalendarDuration =>
      CompoundCalendarDuration(days: this);

  bool get isPositive => inDays > 0;
  bool get isNonPositive => inDays <= 0;
  bool get isNegative => inDays < 0;
  bool get isNonNegative => inDays >= 0;

  /// This duration expressed in [unit], including a fractional part.
  double totalIn(DayUnit unit) => inDays / unit.daysPer;

  /// This duration as a whole number of [unit].
  int roundTo(DayUnit unit, {Rounding rounding = .nearestAwayFromZero}) =>
      rounding.round(totalIn(unit));

  /// This duration rounded to a multiple of [increment] × [unit].
  Days round(
    DayUnit unit, {
    int increment = 1,
    Rounding rounding = .nearestAwayFromZero,
  }) {
    final step = unit.daysPer * increment;
    return Days(rounding.round(inDays / step) * step);
  }

  /// Whether this duration is a whole multiple of [increment] × [unit], i.e.,
  /// whether [round] with the same arguments would leave it unchanged.
  bool isMultipleOf(DayUnit unit, {int increment = 1}) =>
      inDays % (unit.daysPer * increment) == 0;

  /// Decomposes this duration into the given [units].
  ///
  /// The largest listed unit absorbs everything above it; the smallest absorbs
  /// everything below it, rounded according to [rounding]. All components share
  /// the sign of this duration.
  ///
  /// ```dart
  /// days.split({.weeks, .days});
  /// ```
  DayParts split(
    Set<DayUnit> units, {
    Rounding rounding = .nearestAwayFromZero,
  }) {
    assert(units.isNotEmpty);

    final sorted = units.toList()
      ..sort((a, b) => b.daysPer.compareTo(a.daysPer));
    final smallest = sorted.last;

    final values = <DayUnit, int>{};
    var remaining = rounding.round(totalIn(smallest));
    for (final unit in sorted.take(sorted.length - 1)) {
      // `~/` truncates towards zero, so all components share the sign.
      final value = remaining ~/ smallest.per(unit);
      values[unit] = value;
      remaining -= value * smallest.per(unit);
    }
    values[smallest] = remaining;
    return DayParts._(values);
  }

  Days operator +(Days duration) => Days(inDays + duration.inDays);
  Days operator -(Days duration) => Days(inDays - duration.inDays);
  @override
  Days operator -() => Days(-inDays);
  @override
  Days operator *(int factor) => Days(inDays * factor);
  @override
  Days operator ~/(int divisor) => Days(inDays ~/ divisor);
  double operator /(Days divisor) => inDays / divisor.inDays;
  @override
  Days operator %(int divisor) => Days(inDays % divisor);
  @override
  Days remainder(int divisor) => Days(inDays.remainder(divisor));

  Days get absolute => isNegative ? -this : this;

  @override
  int compareTo(Days other) => inDays.compareTo(other.inDays);

  @override
  String toString() => inDays.abs() == 1 ? '$inDays day' : '$inDays days';

  int toJson() => inDays;
}
