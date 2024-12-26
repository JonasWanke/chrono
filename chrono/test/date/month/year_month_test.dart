import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(codecs: const [YearMonthAsIsoStringCodec()]);

  // ignore: missing-test-assertion
  Glados<YearMonth>().test('length', (yearMonth) {
    expectInRange<DaysDuration>(
      yearMonth.length,
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
