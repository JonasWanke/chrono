import 'dart:core' as core;

import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(Instant.fromJson);

  Glados<Instant>().test('fromDurationSinceUnixEpoch', (instant) {
    expect(
      Instant.fromDurationSinceUnixEpoch(instant.durationSinceUnixEpoch),
      instant,
    );
  });

  Glados<core.DateTime>().test('fromCore', (dateTime) {
    expect(Instant.fromCore(dateTime).asCoreDateTimeInLocalZone, dateTime);
  });
}
