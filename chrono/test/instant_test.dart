import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

void main() {
  setChronoGladosDefaults();

  group('Instant', () {
    Glados<Instant>().test('equality', (value) {
      expect(value == value, true);
      expect(value.compareTo(value), 0);
    });
    group('Codecs', () {
      Glados<Instant>().test('InstantAsIsoStringCodec', (value) {
        expect(
          const InstantAsIsoStringCodec().decode(
            const InstantAsIsoStringCodec().encode(value),
          ),
          value,
        );
      });
      Glados<Instant>().test('InstantAsNanosIntCodec', (value) {
        expect(
          const InstantAsNanosIntCodec().decode(
            const InstantAsNanosIntCodec().encode(value),
          ),
          value,
        );
      });
      Glados<int>().test('InstantAsMicrosIntCodec', (value) {
        expect(
          const InstantAsMicrosIntCodec().encode(
            const InstantAsMicrosIntCodec().decode(value),
          ),
          value,
        );
      });
      Glados<int>().test('InstantAsMillisIntCodec', (value) {
        expect(
          const InstantAsMillisIntCodec().encode(
            const InstantAsMillisIntCodec().decode(value),
          ),
          value,
        );
      });
      Glados<int>().test('InstantAsSecondsIntCodec', (value) {
        expect(
          const InstantAsSecondsIntCodec().encode(
            const InstantAsSecondsIntCodec().decode(value),
          ),
          value,
        );
      });
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
      // ignore: lines_longer_than_80_chars
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
