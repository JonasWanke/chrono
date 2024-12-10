import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(codecs: const [MonthDayAsIsoStringCodec()]);

  // ignore: missing-test-assertion
  test('known values', () {
    MonthDay.from(Month.january, 1).unwrap();
    MonthDay.from(Month.february, 28).unwrap();
    MonthDay.from(Month.february, 29).unwrap();
    MonthDay.from(Month.december, 31).unwrap();
  });
}
