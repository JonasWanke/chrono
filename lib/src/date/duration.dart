import '../date_time/duration.dart';
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
        (other is CompoundDuration &&
            months == other.months &&
            days == other.days);
  }

  @override
  int get hashCode => Object.hash(months, days);

  @override
  String toString() => '$months, $days';
}

abstract class FixedDaysDuration extends DaysDuration
    with ComparisonOperatorsFromComparable<FixedDaysDuration>
    implements Comparable<FixedDaysDuration> {
  const FixedDaysDuration();

  Days get inDays;

  @override
  CompoundDaysDuration get asCompoundDaysDuration =>
      CompoundDaysDuration(days: inDays);

  bool get isPositive => inDays.value > 0;
  bool get isNonPositive => inDays.value <= 0;
  bool get isNegative => inDays.value < 0;
  bool get isNonNegative => inDays.value >= 0;

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
      inDays.value.compareTo(other.inDays.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FixedDaysDuration && inDays.value == other.inDays.value);
  @override
  int get hashCode => inDays.value.hashCode;
}

final class Days extends FixedDaysDuration {
  const Days(this.value);
  const Days.fromJson(int json) : this(json);

  static const perWeek = Days(DateTime.daysPerWeek);

  final int value;

  @override
  Days get inDays => this;

  Days operator +(FixedDaysDuration duration) =>
      Days(value + duration.inDays.value);
  Days operator -(FixedDaysDuration duration) =>
      Days(value - duration.inDays.value);
  @override
  Days operator -() => Days(-value);
  @override
  Days operator *(int factor) => Days(value * factor);
  @override
  Days operator ~/(int divisor) => Days(value ~/ divisor);
  @override
  Days operator %(int divisor) => Days(value % divisor);
  @override
  Days remainder(int divisor) => Days(value.remainder(divisor));

  @override
  String toString() => value.abs() == 1 ? '$value day' : '$value days';

  int toJson() => value;
}

final class Weeks extends FixedDaysDuration {
  const Weeks(this.value);
  const Weeks.fromJson(int json) : this(json);

  final int value;

  @override
  Days get inDays => Days.perWeek * value;

  Weeks operator +(Weeks duration) => Weeks(value + duration.value);
  Weeks operator -(Weeks duration) => Weeks(value - duration.value);
  @override
  Weeks operator -() => Weeks(-value);
  @override
  Weeks operator *(int factor) => Weeks(value * factor);
  @override
  Weeks operator ~/(int divisor) => Weeks(value ~/ divisor);
  @override
  Weeks operator %(int divisor) => Weeks(value % divisor);
  @override
  Weeks remainder(int divisor) => Weeks(value.remainder(divisor));

  @override
  String toString() => value.abs() == 1 ? '$value week' : '$value weeks';

  int toJson() => value;
}

abstract class MonthsDuration extends DaysDuration
    with ComparisonOperatorsFromComparable<MonthsDuration>
    implements Comparable<MonthsDuration> {
  const MonthsDuration();

  /// Both are `>= 0` or both are `<= 0`.
  (Years, Months) get inYearsAndMonths {
    final thisMonths = inMonths;
    final years = Years(thisMonths.value ~/ Months.perYear.value);
    final months = thisMonths - years.inMonths;
    return (years, months);
  }

  Months get inMonths;

  @override
  CompoundDaysDuration get asCompoundDaysDuration =>
      CompoundDaysDuration(months: inMonths);

  bool get isPositive => inMonths.value > 0;
  bool get isNonPositive => inMonths.value <= 0;
  bool get isNegative => inMonths.value < 0;
  bool get isNonNegative => inMonths.value >= 0;

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
      inMonths.value.compareTo(other.inMonths.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthsDuration && inMonths.value == other.inMonths.value);
  @override
  int get hashCode => inMonths.value.hashCode;
}

final class Months extends MonthsDuration {
  const Months(this.value);
  const Months.fromJson(int json) : this(json);

  static const perYear = Months(DateTime.monthsPerYear);

  final int value;

  @override
  Months get inMonths => this;

  Months operator +(MonthsDuration duration) =>
      Months(value + duration.inMonths.value);
  Months operator -(MonthsDuration duration) =>
      Months(value - duration.inMonths.value);
  @override
  Months operator -() => Months(-value);
  @override
  Months operator *(int factor) => Months(value * factor);
  @override
  Months operator ~/(int divisor) => Months(value ~/ divisor);
  @override
  Months operator %(int divisor) => Months(value % divisor);
  @override
  Months remainder(int divisor) => Months(value.remainder(divisor));

  @override
  String toString() => value.abs() == 1 ? '$value month' : '$value months';

  int toJson() => value;
}

final class Years extends MonthsDuration {
  const Years(this.value);
  const Years.fromJson(int json) : this(json);

  final int value;

  @override
  (Years, Months) get inYearsAndMonths => (this, const Months(0));
  @override
  Months get inMonths => Months.perYear * value;

  Years operator +(Years duration) => Years(value + duration.value);
  Years operator -(Years duration) => Years(value - duration.value);
  @override
  Years operator -() => Years(-value);
  @override
  Years operator *(int factor) => Years(value * factor);
  @override
  Years operator ~/(int divisor) => Years(value ~/ divisor);
  @override
  Years operator %(int divisor) => Years(value % divisor);
  @override
  Years remainder(int divisor) => Years(value.remainder(divisor));

  @override
  String toString() => value.abs() == 1 ? '$value year' : '$value years';

  int toJson() => value;
}
