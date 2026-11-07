import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  // ignore: missing-test-assertion
  testDataClassBasics(preciseCodecs: const [MonthDayAsIsoStringCodec()]);

  test('inYear and inYearOrNull', () {
    final april23 = MonthDay(4, 23);
    expect(april23.inYear(const Year(2023)), Date(2023, 4, 23));
    expect(april23.inYearOrNull(const Year(2023)), Date(2023, 4, 23));

    final february29 = MonthDay(2, 29);
    expect(february29.inYear(const Year(2024)), Date(2024, 2, 29));
    expect(february29.inYearOrNull(const Year(2024)), Date(2024, 2, 29));
    expect(() => february29.inYear(const Year(2023)), throwsRangeError);
    expect(february29.inYearOrNull(const Year(2023)), null);
  });

  // ignore: missing-test-assertion
  test('known values', () {
    MonthDay.from(Month.january, 1);
    MonthDay.from(Month.february, 28);
    MonthDay.from(Month.february, 29);
    MonthDay.from(Month.december, 31);
  });
}
