import 'package:meta/meta.dart';

import '../../chrono.dart' show Months, TimeDelta;
import '../date/duration.dart';

/// Base class for date and time durations.
///
/// The `Chrono` prefix avoids a conflict with `Duration` from `dart:core` and
/// joins the convention of [ChronoParser], [ChronoFormatter] and friends.
///
/// See also:
///
/// - [CalendarDelta], which covers durations based on an integer number of
///   days or months.
/// - [TimeDelta], which covers durations based on a fixed time like seconds.
/// - [DateTimeDelta], which combines [CalendarDelta] and [TimeDelta].
@immutable
abstract class ChronoDelta {
  const ChronoDelta();

  DateTimeDelta get asDateTimeDelta;

  bool get isZero {
    final compoundDuration = asDateTimeDelta;
    return compoundDuration.months.inMonths == 0 &&
        compoundDuration.days.inDays == 0 &&
        compoundDuration.time.isZero;
  }

  ChronoDelta operator -();
  ChronoDelta operator *(int factor);
  ChronoDelta operator ~/(int divisor);

  /// The remainder of dividing this by [divisor], with the sign of [divisor].
  ///
  /// The divisor is a duration rather than an [int]: `TimeDelta % TimeDelta`
  /// and `CalendarDelta % int` used to be the same operator with incompatible
  /// meanings.
  ChronoDelta operator %(covariant ChronoDelta divisor);

  /// The remainder of dividing this by [divisor], with the sign of `this`.
  ChronoDelta remainder(covariant ChronoDelta divisor);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChronoDelta) return false;

    final thisCompound = asDateTimeDelta;
    final otherCompound = other.asDateTimeDelta;
    return thisCompound.months.inMonths == otherCompound.months.inMonths &&
        thisCompound.days.inDays == otherCompound.days.inDays &&
        thisCompound.time.wholeSeconds == otherCompound.time.wholeSeconds &&
        thisCompound.time.subSecondNanos == otherCompound.time.subSecondNanos;
  }

  @override
  int get hashCode {
    final compound = asDateTimeDelta;
    return Object.hash(
      compound.months.inMonths,
      compound.days.inDays,
      compound.time.wholeSeconds,
      compound.time.subSecondNanos,
    );
  }
}

/// [ChronoDelta] subclass that can represent any duration by combining [Months],
/// [Days], and [TimeDelta].
final class DateTimeDelta extends ChronoDelta {
  DateTimeDelta({
    CalendarDelta? monthsAndDays,
    Months? months,
    Days? days,
    this.time = const TimeDelta.raw(0, 0),
  }) : assert(
         monthsAndDays == null || (months == null && days == null),
         'Cannot specify both `monthsAndDays` and `months`/`days`.',
       ),
       monthsAndDays =
           monthsAndDays?.asMonthsDays ??
           MonthsDays(
             months: months ?? const Months(0),
             days: days ?? const Days(0),
           );

  final MonthsDays monthsAndDays;
  Months get months => monthsAndDays.months;
  Days get days => monthsAndDays.days;
  final TimeDelta time;

  @override
  DateTimeDelta get asDateTimeDelta => this;

  DateTimeDelta operator +(ChronoDelta duration) {
    final DateTimeDelta(:monthsAndDays, time: seconds) =
        duration.asDateTimeDelta;
    return DateTimeDelta(
      monthsAndDays: this.monthsAndDays + monthsAndDays,
      time: time + seconds,
    );
  }

  DateTimeDelta operator -(ChronoDelta other) => this + -other;
  @override
  DateTimeDelta operator -() =>
      DateTimeDelta(monthsAndDays: -monthsAndDays, time: -time);

  @override
  DateTimeDelta operator *(int factor) {
    return DateTimeDelta(
      monthsAndDays: monthsAndDays * factor,
      time: time * factor,
    );
  }

  @override
  DateTimeDelta operator ~/(int divisor) {
    return DateTimeDelta(
      monthsAndDays: monthsAndDays ~/ divisor,
      time: time ~/ divisor,
    );
  }

  @override
  DateTimeDelta operator %(DateTimeDelta divisor) {
    return DateTimeDelta(
      monthsAndDays: monthsAndDays % divisor.monthsAndDays,
      time: time % divisor.time,
    );
  }

  @override
  DateTimeDelta remainder(DateTimeDelta divisor) {
    return DateTimeDelta(
      monthsAndDays: monthsAndDays.remainder(divisor.monthsAndDays),
      time: time.remainder(divisor.time),
    );
  }

  @override
  String toString() => '$months, $days, $time';
}

/// Base class for the results [TimeDelta.split], [Days.split], and
/// [Months.split].
@immutable
abstract class ChronoParts<U extends Enum> {
  const ChronoParts(this.values);

  @protected
  final Map<U, int> values;

  /// The units that were requested when creating this.
  Set<U> get units => values.keys.toSet();

  @protected
  List<U> get allUnitsOrdered;

  @protected
  int get(U unit) {
    final value = values[unit];
    if (value == null) {
      throw StateError('$unit was not requested. Requested units: $units.');
    }
    return value;
  }

  /// The value for [unit], or `null` if it wasn't requested.
  int? maybe(U unit) => values[unit];

  /// Whether [unit] was requested.
  bool has(U unit) => values.containsKey(unit);

  @override
  bool operator ==(Object other) {
    return other is ChronoParts<U> &&
        allUnitsOrdered.every((it) => values[it] == other.values[it]);
  }

  @override
  int get hashCode => Object.hashAll(allUnitsOrdered.map((it) => values[it]));

  @override
  String toString() {
    return allUnitsOrdered.reversed
        .where(values.containsKey)
        .map((it) => '${values[it]} ${it.name}')
        .join(', ');
  }
}
