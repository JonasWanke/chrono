import 'dart:core' as core;

import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(
    jsonConverters: [const InstantAsIsoStringJsonConverter()],
  );
  // [InstantAsEpochMillisecondsIntJsonConverter] and
  // [InstantAsEpochSecondsIntJsonConverter] are lossy.

  Glados<Instant>().test('fromDurationSinceUnixEpoch', (instant) {
    expect(
      Instant.fromDurationSinceUnixEpoch(instant.durationSinceUnixEpoch),
      instant,
    );
  });

  Glados<core.DateTime>().test('fromCore', (dateTime) {
    expect(Instant.fromCore(dateTime).asCoreDateTimeInLocalZone, dateTime);

    final dateTimeInUtc = dateTime.toUtc();
    expect(dateTimeInUtc, Instant.fromCore(dateTimeInUtc).asCoreDateTimeInUtc);
  });

  Glados<Instant>().test('DateTime conversion', (instant) {
    // TODO(JonasWanke): Add this test when conversion is no longer lossy.
    // expect(instant, instant.dateTimeInLocalZone.inLocalZone);
    expect(instant, instant.dateTimeInUtc.inUtc);
  });

  Glados2<Instant, TimeDuration>().test(
    '+, -, and difference(…)',
    (instant, duration) {
      expect(instant + duration - duration, instant);
      expect((instant + duration).difference(instant), duration);
    },
  );
}
