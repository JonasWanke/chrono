import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  // ignore: missing-test-assertion
  testDataClassBasics(preciseCodecs: const [YearMonthAsIsoStringCodec()]);

  // ignore: missing-test-assertion
  Glados<YearMonth>().test('length', (yearMonth) {
    expectInRange<Days>(yearMonth.length, const Days(28), const Days(31));
  });

  test('atDay and atDayOrNull', () {
    final february2023 = YearMonth(2023, 2);
    expect(february2023.atDay(28), Date(2023, 2, 28));
    expect(() => february2023.atDay(29), throwsRangeError);
    expect(() => february2023.atDay(0), throwsRangeError);
    expect(february2023.atDayOrNull(28), Date(2023, 2, 28));
    expect(february2023.atDayOrNull(29), null);
    expect(february2023.atDayOrNull(0), null);
    expect(YearMonth(2024, 2).atDayOrNull(29), Date(2024, 2, 29));
  });

  Glados2<YearMonth, Months>().test('+ and -', (yearMonth, duration) {
    expect(yearMonth + duration - duration, yearMonth);
  });
  Glados<YearMonth>().test('next and previous', (yearMonth) {
    expect(yearMonth.next.previous, yearMonth);
  });
}
