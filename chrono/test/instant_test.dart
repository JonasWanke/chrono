import 'package:chrono/chrono.dart';
import 'package:clock/clock.dart';
import 'package:glados/glados.dart';

import 'utils.dart';

void main() {
  setChronoGladosDefaults();

  group('Instant', () {
    // ignore: missing-test-assertion
    testDataClassBasics<Instant>(
      preciseCodecs: [
        const InstantAsIsoStringCodec(),
        const InstantAsNanosIntCodec(),
      ],
    );

    group('Imprecise codecs', () {
      testCodecStartingFromEncoded(const InstantAsMicrosIntCodec());
      testCodecStartingFromEncoded(const InstantAsMillisIntCodec());
      testCodecStartingFromEncoded(const InstantAsSecondsIntCodec());
    });

    test('now uses the given clock', () {
      final dateTime = DateTime.utc(2023, 4, 23, 12, 34, 56);
      expect(Instant.now(clock: Clock.fixed(dateTime)).toCoreInUtc(), dateTime);
    });

    Glados<Instant>().test('fromDurationSinceUnixEpoch', (timestamp) {
      expect(
        Instant.fromDurationSinceUnixEpoch(timestamp.durationSinceUnixEpoch),
        timestamp,
      );
    });

    Glados<DateTime>().test('core conversion', (dateTime) {
      expect(Instant.fromCore(dateTime).toCoreInLocalZone(), dateTime);

      final dateTimeInUtc = dateTime.toUtc();
      expect(dateTimeInUtc, Instant.fromCore(dateTimeInUtc).toCoreInUtc());
    });

    Glados<Instant>().test('DateTime conversion', (timestamp) {
      // TODO(JonasWanke): Add this test when conversion is no longer lossy.
      // expect(timestamp, timestamp.dateTimeInLocalZone.inLocalZone);
      expect(timestamp, timestamp.dateTimeInUtc.inUtc);
    });

    Glados2<Instant, TimeDelta>().test('+, -, and difference(…)', (
      timestamp,
      duration,
    ) {
      expect(timestamp + duration - duration, timestamp);
      expect((timestamp + duration).difference(timestamp), duration);
    });
  });
}
