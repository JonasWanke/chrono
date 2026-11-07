import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

void main() {
  test('DateTime projections read the fields as they are', () {
    final dateTime = DateTime(2023, 4, 23, 12, 34, 56, 123, 456);
    expect(dateTime.chronoDate, Date(2023, 4, 23));
    expect(dateTime.chronoTime, Time(12, 34, 56, 123, 456));
    expect(
      dateTime.chronoDateTime,
      dateTime.chronoDate.at(dateTime.chronoTime),
    );
    expect(dateTime.chronoYear, const Year(2023));
    expect(dateTime.chronoMonth, Month.april);
    expect(dateTime.chronoYearMonth, YearMonth(2023, 4));
    expect(dateTime.chronoMonthDay, MonthDay(4, 23));
    expect(dateTime.chronoWeekday, Weekday.sunday);
    expect(
      dateTime.chronoYearWeek(WeekConfig.iso),
      Date(2023, 4, 23).yearWeek(WeekConfig.iso),
    );
  });

  test('chronoInstant uses the moment, regardless of isUtc', () {
    final utc = DateTime.utc(2023, 4, 23, 12);
    expect(utc.chronoInstant, utc.toLocal().chronoInstant);
    expect(utc.chronoInstant.toCoreInUtc(), utc);
  });

  test('toChronoTimeDelta', () {
    expect(
      const Duration(seconds: 1, microseconds: 5).toChronoTimeDelta(),
      TimeDelta(seconds: 1, micros: 5),
    );
  });
}
