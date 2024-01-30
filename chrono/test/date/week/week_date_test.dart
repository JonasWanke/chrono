import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(const WeekDateStringJsonConverter());

  Glados<WeekDate>().test('asDate', (weekDate) {
    expect(weekDate.asDate.asWeekDate, weekDate);
  });
  Glados<WeekDate>().test('asOrdinalDate', (weekDate) {
    expect(weekDate.asOrdinalDate.asWeekDate, weekDate);
  });

  // Arithmetic with `MonthsDuration` isn't always round-trippable.
  Glados2<WeekDate, FixedDaysDuration>().test('+ and -', (date, duration) {
    expect(date + duration - duration, date);
  });
  Glados<WeekDate>().test('next and previous', (weekDate) {
    expect(weekDate.next.previous, weekDate);
  });
}
