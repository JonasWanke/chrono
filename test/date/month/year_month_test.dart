import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(YearMonth.fromJson);

  // ignore: missing-test-assertion
  Glados<YearMonth>().test('lengthInDays', (yearMonth) {
    expectInRange<FixedDaysDuration>(
      yearMonth.lengthInDays,
      const Days(28),
      const Days(31),
    );
  });

  Glados2<YearMonth, MonthsDuration>().test('+ and -', (yearMonth, duration) {
    expect(yearMonth + duration - duration, yearMonth);
  });
  Glados<YearMonth>().test('next and previous', (yearMonth) {
    expect(yearMonth.next.previous, yearMonth);
  });
}
