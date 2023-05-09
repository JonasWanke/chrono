import 'package:meta/meta.dart';

import 'utils.dart';

@immutable
sealed class DaysPeriod {
  const DaysPeriod();

  (Months, Days) get inMonthsAndDays;

  DaysPeriod operator -();
  DaysPeriod operator *(int factor);
}

sealed class FixedDaysPeriod extends DaysPeriod
    with ComparisonOperatorsFromComparable<FixedDaysPeriod>
    implements Comparable<FixedDaysPeriod> {
  const FixedDaysPeriod();

  Days get inDays;

  @override
  (Months, Days) get inMonthsAndDays => (const Months(0), inDays);

  @override
  FixedDaysPeriod operator -();
  @override
  FixedDaysPeriod operator *(int factor);

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

  final int value;

  @override
  Days get inDays => this;

  Days operator +(Days period) => Days(value + period.value);
  Days operator -(Days period) => Days(value - period.value);
  @override
  Days operator -() => Days(-value);
  @override
  Days operator *(int factor) => Days(value * factor);

  @override
  String toString() => value.abs() == 1 ? '$value day' : '$value days';

  int toJson() => value;
}

final class Weeks extends FixedDaysPeriod {
  const Weeks(this.value);
  const Weeks.fromJson(int json) : this(json);

  static const daysPerWeek = DateTime.daysPerWeek;

  final int value;

  @override
  Days get inDays => Days(value * daysPerWeek);

  Weeks operator +(Weeks period) => Weeks(value + period.value);
  Weeks operator -(Weeks period) => Weeks(value - period.value);
  @override
  Weeks operator -() => Weeks(-value);
  @override
  Weeks operator *(int factor) => Weeks(value * factor);

  @override
  String toString() => value.abs() == 1 ? '$value week' : '$value weeks';

  int toJson() => value;
}

sealed class MonthsPeriod extends DaysPeriod
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

  @override
  MonthsPeriod operator -();
  @override
  MonthsPeriod operator *(int factor);

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

  Months operator +(Months period) => Months(value + period.value);
  Months operator -(Months period) => Months(value - period.value);
  @override
  Months operator -() => Months(-value);
  @override
  Months operator *(int factor) => Months(value * factor);

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
  String toString() => value.abs() == 1 ? '$value year' : '$value years';

  int toJson() => value;
}
