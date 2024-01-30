import 'dart:core' as core;

import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(const DateTimeStringJsonConverter());

  Glados<DateTime>().test('fromDurationSinceUnixEpoch', (dateTime) {
    expect(
      DateTime.fromDurationSinceUnixEpoch(dateTime.durationSinceUnixEpoch),
      dateTime,
    );
  });

  Glados<core.DateTime>().test('fromCore', (dateTime) {
    expect(DateTime.fromCore(dateTime).asCoreDateTimeInLocalZone, dateTime);

    final dateTimeInUtc = dateTime.toUtc();
    expect(dateTimeInUtc, DateTime.fromCore(dateTimeInUtc).asCoreDateTimeInUtc);
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
