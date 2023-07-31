import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(DateTime.fromJson);

  Glados<DateTime>().test('fromDurationSinceUnixEpoch', (dateTime) {
    expect(
      DateTime.fromDurationSinceUnixEpoch(dateTime.durationSinceUnixEpoch),
      dateTime,
    );
  });

  Glados<DateTime>().test('fromCore', (dateTime) {
    expect(DateTime.fromCore(dateTime.asCoreDateTimeInLocalZone), dateTime);
    expect(DateTime.fromCore(dateTime.asCoreDateTimeInUtc), dateTime);
  });

  Glados3<DateTime, FixedDaysDuration, TimeDuration>().test(
    '+ and -',
    (dateTime, daysDuration, timeDuration) {
      expect(
        dateTime + daysDuration + timeDuration - daysDuration - timeDuration,
        dateTime,
      );
    },
  );
}
