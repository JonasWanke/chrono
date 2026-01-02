import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(preciseCodecs: const [MonthDayAsIsoStringCodec()]);

  // ignore: missing-test-assertion
  test('known values', () {
    MonthDay.from(Month.january, 1);
    MonthDay.from(Month.february, 28);
    MonthDay.from(Month.february, 29);
    MonthDay.from(Month.december, 31);
  });
}
