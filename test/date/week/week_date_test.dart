import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(WeekDate.fromJson);

  Glados<WeekDate>().test('asDate', (weekDate) {
    expect(weekDate.asDate.asWeekDate, weekDate);
  });
  Glados<WeekDate>().test('asOrdinalDate', (weekDate) {
    expect(weekDate.asOrdinalDate.asWeekDate, weekDate);
  });

  Glados2<WeekDate, DaysDuration>().test('+ and -', (weekDate, duration) {
    expect(weekDate + duration - duration, weekDate);
  });
  Glados<WeekDate>().test('next and previous', (weekDate) {
    expect(weekDate.next.previous, weekDate);
  });
}
