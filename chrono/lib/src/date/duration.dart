import 'package:meta/meta.dart';

import '../date_time/duration.dart';
import '../rounding.dart';
import '../time/duration.dart';
import '../utils.dart';

/// A [ChronoDelta] based on an integer number of days or months.
///
/// This is different to [TimeDelta] because days can be shorter or longer
/// than 24 hours and months have a varying of days.
///
/// See also:
///
/// - [Months], which represents an integer number of months.
/// - [Days], which represents an integer number of days.
/// - [MonthsDays], which combines [Months] and [Days].
/// - [TimeDelta], which covers durations based on a fixed time like seconds.
/// - [ChronoDelta], which is the base class for date and time durations.
abstract class CalendarDelta extends ChronoDelta {
  const CalendarDelta();

  MonthsDays get asMonthsDays;
  @override
  DateTimeDelta get asDateTimeDelta =>
      DateTimeDelta(monthsAndDays: asMonthsDays);

  @override
  CalendarDelta operator -();
  @override
  CalendarDelta operator *(int factor);
  @override
  CalendarDelta operator ~/(int divisor);
  @override
  CalendarDelta operator %(covariant CalendarDelta divisor);
  @override
  CalendarDelta remainder(covariant CalendarDelta divisor);
}

/// [CalendarDelta] subclass that can represent any days-based duration by
/// combining [Months] and [Days].
final class MonthsDays extends CalendarDelta {
  const MonthsDays({this.months = const Months(0), this.days = const Days(0)});

  final Months months;
  final Days days;

  @override
  MonthsDays get asMonthsDays => this;

  MonthsDays operator +(CalendarDelta duration) {
    final MonthsDays(:months, :days) = duration.asMonthsDays;
    return MonthsDays(months: this.months + months, days: this.days + days);
  }

  MonthsDays operator -(CalendarDelta duration) => this + (-duration);
  @override
  MonthsDays operator -() => MonthsDays(months: -months, days: -days);
  @override
  MonthsDays operator *(int factor) =>
      MonthsDays(months: months * factor, days: days * factor);
  @override
  MonthsDays operator ~/(int divisor) {
    return MonthsDays(months: months ~/ divisor, days: days ~/ divisor);
  }

  @override
  MonthsDays operator %(MonthsDays divisor) =>
      MonthsDays(months: months % divisor.months, days: days % divisor.days);
  @override
  MonthsDays remainder(MonthsDays divisor) {
    return MonthsDays(
      months: months.remainder(divisor.months),
      days: days.remainder(divisor.days),
    );
  }

  @override
  String toString() => '$months, $days';
}

/// A unit of the month family: A length that is an exact, context-free multiple
/// of a month.
///
/// Members of this enum are units rather than types precisely because they are
/// exact multiples of each other – a year is *always* twelve months.
enum MonthUnit {
  months(1),
  quarters(3),
  years(Months.perYear),
  decades(10 * Months.perYear),
  centuries(100 * Months.perYear),
  millennia(1000 * Months.perYear);

  const MonthUnit(this.monthsPer);

  /// The number of months in one of this unit.
  final int monthsPer;

  /// How many of `this` fit in one [larger], e.g.,
  /// `MonthUnit.months.per(MonthUnit.years) == 12`.
  int per(MonthUnit larger) {
    assert(larger.monthsPer >= monthsPer, 'Argument must be the larger unit.');
    return larger.monthsPer ~/ monthsPer;
  }
}

/// The result of [Months.split]: one value per requested [MonthUnit].
///
/// Reading a unit that wasn't requested throws instead of returning zero, since
/// that is almost certainly a bug and zero would hide it. Use [maybe] or [has]
/// when the requested set isn't statically known.
///
/// All components share the sign of the duration they were split from.
@immutable
final class MonthParts extends ChronoParts<MonthUnit> {
  const MonthParts._(super.values);

  @override
  List<MonthUnit> get allUnitsOrdered => MonthUnit.values;

  int get months => get(.months);
  int get quarters => get(.quarters);
  int get years => get(.years);
  int get decades => get(.decades);
  int get centuries => get(.centuries);
  int get millennia => get(.millennia);
}

/// An integer number of months.
///
/// This is different to [TimeDelta] because months have a varying number of
/// days.
final class Months extends CalendarDelta
    with ComparisonOperatorsFromComparable<Months>
    implements Comparable<Months> {
  const Months(this.inMonths);
  const Months.fromJson(int json) : this(json);

  /// The months in [years] years.
  const Months.fromYears(int years) : inMonths = years * perYear;

  /// The number of months in a year.
  static const perYear = 12;

  /// The months in a year.
  static const year = Months(perYear);

  final int inMonths;

  @override
  MonthsDays get asMonthsDays => MonthsDays(months: this);

  bool get isPositive => inMonths > 0;
  bool get isNonPositive => inMonths <= 0;
  bool get isNegative => inMonths < 0;
  bool get isNonNegative => inMonths >= 0;

  /// This duration expressed in [unit], including a fractional part.
  double totalIn(MonthUnit unit) => inMonths / unit.monthsPer;

  /// This duration as a whole number of [unit].
  int roundTo(MonthUnit unit, {Rounding rounding = .nearestAwayFromZero}) =>
      rounding.round(totalIn(unit));

  /// This duration rounded to a multiple of [increment] × [unit].
  Months round(
    MonthUnit unit, {
    int increment = 1,
    Rounding rounding = .nearestAwayFromZero,
  }) {
    final step = unit.monthsPer * increment;
    return Months(rounding.round(inMonths / step) * step);
  }

  /// Whether this duration is a whole multiple of [increment] × [unit], i.e.,
  /// whether [round] with the same arguments would leave it unchanged.
  bool isMultipleOf(MonthUnit unit, {int increment = 1}) =>
      inMonths % (unit.monthsPer * increment) == 0;

  /// Decomposes this duration into the given [units].
  ///
  /// The largest listed unit absorbs everything above it; the smallest absorbs
  /// everything below it, rounded according to [rounding]. All components share
  /// the sign of this duration.
  ///
  /// ```dart
  /// months.split({.years, .months});
  /// ```
  MonthParts split(
    Set<MonthUnit> units, {
    Rounding rounding = .nearestAwayFromZero,
  }) => MonthParts._(
    splitIntoUnits(inMonths, units, (it) => it.monthsPer, rounding),
  );

  Months operator +(Months duration) => Months(inMonths + duration.inMonths);
  Months operator -(Months duration) => Months(inMonths - duration.inMonths);
  @override
  Months operator -() => Months(-inMonths);
  @override
  Months operator *(int factor) => Months(inMonths * factor);
  @override
  Months operator ~/(int divisor) => Months(inMonths ~/ divisor);
  double operator /(Months divisor) => inMonths / divisor.inMonths;
  @override
  Months operator %(Months divisor) => Months(inMonths % divisor.inMonths);
  @override
  Months remainder(Months divisor) =>
      Months(inMonths.remainder(divisor.inMonths));

  Months get absolute => isNegative ? -this : this;

  @override
  int compareTo(Months other) => inMonths.compareTo(other.inMonths);

  @override
  String toString() =>
      inMonths.abs() == 1 ? '$inMonths month' : '$inMonths months';

  int toJson() => inMonths;
}

/// A unit of the day family: A length that is an exact, context-free multiple
/// of a day.
///
/// Members of this enum are units rather than types precisely because they are
/// exact multiples of each other – a week is *always* seven days.
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
final class Days extends CalendarDelta
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
  int get asNormalHours => TimeUnit.hours.per(.normalDays) * inDays;
  int get asNormalMinutes => TimeUnit.minutes.per(.normalDays) * inDays;
  int get asNormalSeconds => TimeUnit.seconds.per(.normalDays) * inDays;
  int get asNormalMillis => TimeUnit.millis.per(.normalDays) * inDays;
  int get asNormalMicros => TimeUnit.micros.per(.normalDays) * inDays;
  int get asNormalNanos => TimeUnit.nanos.per(.normalDays) * inDays;

  @override
  MonthsDays get asMonthsDays => MonthsDays(days: this);

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
  }) => DayParts._(splitIntoUnits(inDays, units, (it) => it.daysPer, rounding));

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
  Days operator %(Days divisor) => Days(inDays % divisor.inDays);
  @override
  Days remainder(Days divisor) => Days(inDays.remainder(divisor.inDays));

  Days get absolute => isNegative ? -this : this;

  @override
  int compareTo(Days other) => inDays.compareTo(other.inDays);

  @override
  String toString() => inDays.abs() == 1 ? '$inDays day' : '$inDays days';

  int toJson() => inDays;
}
