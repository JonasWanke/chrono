import '../date_time/duration.dart';
import '../time/duration.dart';
import '../utils.dart';

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

final class CompoundDaysDuration extends DaysDuration {
  const CompoundDaysDuration({
    this.months = const Months(0),
    this.days = const Days(0),
  });

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
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CompoundDaysDuration &&
            months == other.months &&
            days == other.days);
  }

  @override
  int get hashCode => Object.hash(months, days);

  @override
  String toString() => '$months, $days';
}

abstract class MonthsDuration extends DaysDuration
    with ComparisonOperatorsFromComparable<MonthsDuration>
    implements Comparable<MonthsDuration> {
  const MonthsDuration();

  /// Both are `>= 0` or both are `<= 0`.
  (Years, Months) get asYearsAndMonths {
    final thisMonths = asMonths;
    final years = Years(thisMonths.inMonths ~/ Months.perYear);
    final months = thisMonths - years.asMonths;
    return (years, months);
  }

  Months get asMonths;

  @override
  CompoundDaysDuration get asCompoundDaysDuration =>
      CompoundDaysDuration(months: asMonths);

  bool get isPositive => asMonths.inMonths > 0;
  bool get isNonPositive => asMonths.inMonths <= 0;
  bool get isNegative => asMonths.inMonths < 0;
  bool get isNonNegative => asMonths.inMonths >= 0;

  @override
  MonthsDuration operator -();
  @override
  MonthsDuration operator *(int factor);
  @override
  MonthsDuration operator ~/(int divisor);
  @override
  MonthsDuration operator %(int divisor);
  @override
  MonthsDuration remainder(int divisor);

  @override
  int compareTo(MonthsDuration other) =>
      asMonths.inMonths.compareTo(other.asMonths.inMonths);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthsDuration && asMonths.inMonths == other.asMonths.inMonths);
  @override
  int get hashCode => asMonths.inMonths.hashCode;
}

final class Months extends MonthsDuration {
  const Months(this.inMonths);
  const Months.fromJson(int json) : this(json);

  static const perYear = 12;

  final int inMonths;

  @override
  Months get asMonths => this;

  Months operator +(MonthsDuration duration) =>
      Months(inMonths + duration.asMonths.inMonths);
  Months operator -(MonthsDuration duration) =>
      Months(inMonths - duration.asMonths.inMonths);
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
  String toString() =>
      inMonths.abs() == 1 ? '$inMonths month' : '$inMonths months';

  int toJson() => inMonths;
}

final class Years extends MonthsDuration {
  const Years(this.inYears);
  const Years.fromJson(int json) : this(json);

  final int inYears;

  @override
  (Years, Months) get asYearsAndMonths => (this, const Months(0));
  @override
  Months get asMonths => Months(inYears * Months.perYear);

  Years operator +(Years duration) => Years(inYears + duration.inYears);
  Years operator -(Years duration) => Years(inYears - duration.inYears);
  @override
  Years operator -() => Years(-inYears);
  @override
  Years operator *(int factor) => Years(inYears * factor);
  @override
  Years operator ~/(int divisor) => Years(inYears ~/ divisor);
  @override
  Years operator %(int divisor) => Years(inYears % divisor);
  @override
  Years remainder(int divisor) => Years(inYears.remainder(divisor));

  @override
  String toString() => inYears.abs() == 1 ? '$inYears year' : '$inYears years';

  int toJson() => inYears;
}

abstract class FixedDaysDuration extends DaysDuration
    with ComparisonOperatorsFromComparable<FixedDaysDuration>
    implements Comparable<FixedDaysDuration> {
  const FixedDaysDuration();

  Days get asDays;
  Hours get asNormalHours => Hours(asDays.inDays * Hours.perNormalDay);
  Minutes get asNormalMinutes => asNormalHours.asMinutes;
  Seconds get asNormalSeconds => asNormalHours.asSeconds;
  Milliseconds get asNormalMilliseconds => asNormalHours.asMilliseconds;
  Microseconds get asNormalMicroseconds => asNormalHours.asMicroseconds;
  Nanoseconds get asNormalNanoseconds => asNormalHours.asNanoseconds;

  @override
  CompoundDaysDuration get asCompoundDaysDuration =>
      CompoundDaysDuration(days: asDays);

  bool get isPositive => asDays.inDays > 0;
  bool get isNonPositive => asDays.inDays <= 0;
  bool get isNegative => asDays.inDays < 0;
  bool get isNonNegative => asDays.inDays >= 0;

  @override
  FixedDaysDuration operator -();
  @override
  FixedDaysDuration operator *(int factor);
  @override
  FixedDaysDuration operator ~/(int divisor);
  @override
  FixedDaysDuration operator %(int divisor);
  @override
  FixedDaysDuration remainder(int divisor);

  @override
  int compareTo(FixedDaysDuration other) =>
      asDays.inDays.compareTo(other.asDays.inDays);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is FixedDaysDuration && asDays.inDays == other.asDays.inDays);
  }

  @override
  int get hashCode => asDays.inDays.hashCode;
}

final class Days extends FixedDaysDuration {
  const Days(this.inDays);
  const Days.fromJson(int json) : this(json);

  static const perWeek = 7;

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
  String toString() => inDays.abs() == 1 ? '$inDays day' : '$inDays days';

  int toJson() => inDays;
}

final class Weeks extends FixedDaysDuration {
  const Weeks(this.inWeeks);
  const Weeks.fromJson(int json) : this(json);

  final int inWeeks;

  @override
  Days get asDays => Days(inWeeks * Days.perWeek);

  Weeks operator +(Weeks duration) => Weeks(inWeeks + duration.inWeeks);
  Weeks operator -(Weeks duration) => Weeks(inWeeks - duration.inWeeks);
  @override
  Weeks operator -() => Weeks(-inWeeks);
  @override
  Weeks operator *(int factor) => Weeks(inWeeks * factor);
  @override
  Weeks operator ~/(int divisor) => Weeks(inWeeks ~/ divisor);
  @override
  Weeks operator %(int divisor) => Weeks(inWeeks % divisor);
  @override
  Weeks remainder(int divisor) => Weeks(inWeeks.remainder(divisor));

  @override
  String toString() => inWeeks.abs() == 1 ? '$inWeeks week' : '$inWeeks weeks';

  int toJson() => inWeeks;
}
