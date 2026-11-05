import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

void main() {
  setChronoGladosDefaults();

  group('fromDurationSinceUnixEpoch(…)', () {
    test('at the epoch', () {
      expect(
        ZonedDateTime.fromDurationSinceUnixEpoch(TimeDelta()).utcDateTime,
        CDateTime.unixEpoch,
      );
    });
    test('after the epoch', () {
      expect(
        ZonedDateTime.fromDurationSinceUnixEpoch(
          TimeDelta(hours: 5),
        ).utcDateTime,
        CDateTime.fromRaw(1970, 1, 1, 5),
      );
    });
    test('before the epoch', () {
      expect(
        ZonedDateTime.fromDurationSinceUnixEpoch(
          TimeDelta(hours: -5),
        ).utcDateTime,
        CDateTime.fromRaw(1969, 12, 31, 19),
      );
      expect(
        ZonedDateTime.fromDurationSinceUnixEpoch(
          TimeDelta(normalDays: -1),
        ).utcDateTime,
        CDateTime.fromRaw(1969, 12, 31),
      );
    });
    Glados<TimeDelta>().test('roundtrips through durationSinceUnixEpoch', (
      duration,
    ) {
      expect(
        ZonedDateTime.fromDurationSinceUnixEpoch(
          duration,
        ).durationSinceUnixEpoch,
        duration,
      );
    });
    Glados<TimeDelta>().test('agrees with CDateTime', (duration) {
      expect(
        ZonedDateTime.fromDurationSinceUnixEpoch(duration).utcDateTime,
        CDateTime.fromDurationSinceUnixEpoch(duration),
      );
    });
  });

  group('FixedOffset.toString()', () {
    test('zero', () {
      expect(FixedOffset.zero.toString(), '+00:00');
    });
    test('whole minutes', () {
      expect(
        FixedOffset.east(TimeDelta(hours: 1, minutes: 30)).toString(),
        '+01:30',
      );
      expect(
        FixedOffset.west(TimeDelta(hours: 4, minutes: 5)).toString(),
        '-04:05',
      );
    });
    test('with seconds', () {
      expect(
        FixedOffset.east(
          TimeDelta(hours: 1, minutes: 2, seconds: 3),
        ).toString(),
        '+01:02:03',
      );
      expect(
        FixedOffset.west(
          TimeDelta(hours: 1, minutes: 2, seconds: 3),
        ).toString(),
        '-01:02:03',
      );
    });
  });
}
