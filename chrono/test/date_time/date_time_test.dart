import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(codecs: const [CDateTimeAsIsoStringCodec()]);

  Glados<CDateTime>().test('fromDurationSinceUnixEpoch', (dateTime) {
    expect(
      CDateTime.fromDurationSinceUnixEpoch(dateTime.durationSinceUnixEpoch),
      dateTime,
    );
  });

  Glados<DateTime>().test('fromCore', (dateTime) {
    expect(CDateTime.fromCore(dateTime).asCoreDateTimeInLocalZone, dateTime);

    final dateTimeInUtc = dateTime.toUtc();
    expect(
      dateTimeInUtc,
      CDateTime.fromCore(dateTimeInUtc).asCoreDateTimeInUtc,
    );
  });

  Glados3<CDateTime, DaysDuration, TimeDuration>().test(
    '+ and -',
    (dateTime, daysDuration, timeDuration) {
      expect(
        dateTime + daysDuration + timeDuration - daysDuration - timeDuration,
        dateTime,
      );
    },
  );

  test('difference(…)', () {
    final base =
        Date.from(const Year(2023), Month.october, 12).unwrap().at(Time.noon);

    expect(
      (base + const Hours(5)).difference(base),
      const Hours(5).asCompoundDuration,
    );
    expect(
      (base + const Days(1)).difference(base),
      const Days(1).asCompoundDuration,
    );
    expect(
      (base + const Days(1) + const Hours(5)).difference(base),
      CompoundDuration(days: const Days(1), seconds: const Hours(5)),
    );

    expect(
      (base - const Hours(5)).difference(base),
      const Hours(-5).asCompoundDuration,
    );
    expect(
      (base - const Days(1)).difference(base),
      const Days(-1).asCompoundDuration,
    );
    expect(
      (base - const Days(1) - const Hours(5)).difference(base),
      CompoundDuration(days: const Days(-1), seconds: const Hours(-5)),
    );

    expect(
      (base + const Days(1) - const Hours(5)).difference(base),
      CompoundDuration(seconds: const Hours(24 - 5)),
    );
    expect(
      (base - const Days(1) + const Hours(5)).difference(base),
      CompoundDuration(seconds: const Hours(-(24 - 5))),
    );
  });
}
