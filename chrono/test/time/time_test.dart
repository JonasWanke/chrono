import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(codecs: const [TimeAsIsoStringCodec()]);

  Glados<Time>().test('fromTimeSinceMidnight', (time) {
    expect(
      Time.fromTimeSinceMidnight(time.nanosecondsSinceMidnight).unwrap(),
      time,
    );
  });

  Glados2<Time, TimeDuration>().test(
    '+, -, and difference(…)',
    (time, duration) {
      final timePlusDuration = time.add(duration).unwrapOrNull();
      if (timePlusDuration == null) return;

      expect(timePlusDuration.subtract(duration).unwrap(), time);
      expect(timePlusDuration.difference(time), duration);
    },
  );
}
