import 'package:meta/meta.dart';

import 'period.dart';
import 'period_time.dart';
import 'utils.dart';

@immutable
abstract class DaysPeriod extends Period {
  const DaysPeriod();

  (Months, Days) get inMonthsAndDays;

  @override
  CompoundPeriod get inMonthsAndDaysAndSeconds {
    final (months, days) = inMonthsAndDays;
    return CompoundPeriod(months, days, const Seconds(0));
  }

  @override
  DaysPeriod operator -();
  @override
  DaysPeriod operator *(int factor);
  @override
  DaysPeriod operator ~/(int divisor);
  @override
  DaysPeriod operator %(int divisor);
}

abstract class FixedDaysPeriod extends DaysPeriod
    with ComparisonOperatorsFromComparable<FixedDaysPeriod>
    implements Comparable<FixedDaysPeriod> {
  const FixedDaysPeriod();

  Days get inDays;

  @override
  (Months, Days) get inMonthsAndDays => (const Months(0), inDays);

  bool get isPositive => inDays.value > 0;
  bool get isNonPositive => inDays.value <= 0;
  bool get isNegative => inDays.value < 0;
  bool get isNonNegative => inDays.value >= 0;

  @override
  FixedDaysPeriod operator -();
  @override
  FixedDaysPeriod operator *(int factor);
  @override
  FixedDaysPeriod operator ~/(int divisor);
  @override
  FixedDaysPeriod operator %(int divisor);

  @override
  int compareTo(FixedDaysPeriod other) =>
      inDays.value.compareTo(other.inDays.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FixedDaysPeriod && inDays.value == other.inDays.value);
  @override
  int get hashCode => inDays.value.hashCode;
}

final class Days extends FixedDaysPeriod {
  const Days(this.value);
  const Days.fromJson(int json) : this(json);

  static const perWeek = Days(DateTime.daysPerWeek);

  final int value;

  @override
  Days get inDays => this;

  Days operator +(FixedDaysPeriod period) => Days(value + period.inDays.value);
  Days operator -(FixedDaysPeriod period) => Days(value - period.inDays.value);
  @override
  Days operator -() => Days(-value);
  @override
  Days operator *(int factor) => Days(value * factor);
  @override
  Days operator ~/(int divisor) => Days(value ~/ divisor);
  @override
  Days operator %(int divisor) => Days(value % divisor);

  @override
  String toString() => value.abs() == 1 ? '$value day' : '$value days';

  int toJson() => value;
}

final class Weeks extends FixedDaysPeriod {
  const Weeks(this.value);
  const Weeks.fromJson(int json) : this(json);

  final int value;

  @override
  Days get inDays => Days.perWeek * value;

  Weeks operator +(Weeks period) => Weeks(value + period.value);
  Weeks operator -(Weeks period) => Weeks(value - period.value);
  @override
  Weeks operator -() => Weeks(-value);
  @override
  Weeks operator *(int factor) => Weeks(value * factor);
  @override
  Weeks operator ~/(int divisor) => Weeks(value ~/ divisor);
  @override
  Weeks operator %(int divisor) => Weeks(value % divisor);

  @override
  String toString() => value.abs() == 1 ? '$value week' : '$value weeks';

  int toJson() => value;
}

abstract class MonthsPeriod extends DaysPeriod
    with ComparisonOperatorsFromComparable<MonthsPeriod>
    implements Comparable<MonthsPeriod> {
  const MonthsPeriod();

  /// Both are `>= 0` or both are `<= 0`.
  (Years, Months) get inYearsAndMonths {
    final thisMonths = inMonths;
    final years = Years(thisMonths.value ~/ Months.perYear.value);
    final months = thisMonths - years.inMonths;
    return (years, months);
  }

  Months get inMonths;

  @override
  (Months, Days) get inMonthsAndDays => (inMonths, const Days(0));

  bool get isPositive => inMonths.value > 0;
  bool get isNonPositive => inMonths.value <= 0;
  bool get isNegative => inMonths.value < 0;
  bool get isNonNegative => inMonths.value >= 0;

  @override
  MonthsPeriod operator -();
  @override
  MonthsPeriod operator *(int factor);
  @override
  MonthsPeriod operator ~/(int divisor);
  @override
  MonthsPeriod operator %(int divisor);

  @override
  int compareTo(MonthsPeriod other) =>
      inMonths.value.compareTo(other.inMonths.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthsPeriod && inMonths.value == other.inMonths.value);
  @override
  int get hashCode => inMonths.value.hashCode;
}

final class Months extends MonthsPeriod {
  const Months(this.value);
  const Months.fromJson(int json) : this(json);

  static const perYear = Months(DateTime.monthsPerYear);

  final int value;

  @override
  Months get inMonths => this;

  Months operator +(MonthsPeriod period) =>
      Months(value + period.inMonths.value);
  Months operator -(MonthsPeriod period) =>
      Months(value - period.inMonths.value);
  @override
  Months operator -() => Months(-value);
  @override
  Months operator *(int factor) => Months(value * factor);
  @override
  Months operator ~/(int divisor) => Months(value ~/ divisor);
  @override
  Months operator %(int divisor) => Months(value % divisor);

  @override
  String toString() => value.abs() == 1 ? '$value month' : '$value months';

  int toJson() => value;
}

final class Years extends MonthsPeriod {
  const Years(this.value);
  const Years.fromJson(int json) : this(json);

  final int value;

  @override
  (Years, Months) get inYearsAndMonths => (this, const Months(0));
  @override
  Months get inMonths => Months.perYear * value;

  Years operator +(Years period) => Years(value + period.value);
  Years operator -(Years period) => Years(value - period.value);
  @override
  Years operator -() => Years(-value);
  @override
  Years operator *(int factor) => Years(value * factor);
  @override
  Years operator ~/(int divisor) => Years(value ~/ divisor);
  @override
  Years operator %(int divisor) => Years(value % divisor);

  @override
  String toString() => value.abs() == 1 ? '$value year' : '$value years';

  int toJson() => value;
}
