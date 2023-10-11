import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(Time.fromJson);

  Glados<Time>().test('fromTimeSinceMidnight', (time) {
    expect(
      Time.fromTimeSinceMidnight(time.fractionalSecondsSinceMidnight).unwrap(),
      time,
    );
  });
}
