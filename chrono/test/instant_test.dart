import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import 'utils.dart';

void main() {
  setChronoGladosDefaults();

  group('Instant', () {
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

    Glados<Instant>().test('fromDurationSinceUnixEpoch', (timestamp) {
      expect(
        Instant.fromDurationSinceUnixEpoch(timestamp.durationSinceUnixEpoch),
        timestamp,
      );
    });

    Glados<DateTime>().test('core conversion', (dateTime) {
      expect(Instant.fromCore(dateTime).asCoreDateTimeInLocalZone, dateTime);

      final dateTimeInUtc = dateTime.toUtc();
      expect(
        dateTimeInUtc,
        Instant.fromCore(dateTimeInUtc).asCoreDateTimeInUtc,
      );
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
