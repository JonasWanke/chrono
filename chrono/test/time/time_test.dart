import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(codecs: const [TimeAsIsoStringCodec()]);

  Glados<Time>().test('fromTimeSinceMidnight', (time) {
    expect(Time.fromTimeSinceMidnight(time.timeSinceMidnight), time);
  });

  Glados2<Time, TimeDelta>().test('+, -, and difference(…)', (time, timeDelta) {
    final timePlusDuration = time.addChecked(timeDelta);
    if (timePlusDuration == null) return;

    expect(timePlusDuration - timeDelta, time);
    expect(timePlusDuration.difference(time), timeDelta);
  });
}
