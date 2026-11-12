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
        ZonedDateTime.fromDurationSinceUnixEpoch(TimeDelta(hours: 5))
            .utcDateTime,
        CDateTime(1970, 1, 1, 5),
      );
    });
    test('before the epoch', () {
      expect(
        ZonedDateTime.fromDurationSinceUnixEpoch(TimeDelta(hours: -5))
            .utcDateTime,
        CDateTime(1969, 12, 31, 19),
      );
      expect(
        ZonedDateTime.fromDurationSinceUnixEpoch(TimeDelta(normalDays: -1))
            .utcDateTime,
        CDateTime(1969, 12, 31),
      );
    });
    Glados<TimeDelta>().test('roundtrips through durationSinceUnixEpoch', (
      duration,
    ) {
      expect(
        ZonedDateTime.fromDurationSinceUnixEpoch(duration)
            .durationSinceUnixEpoch,
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
        FixedOffset.east(TimeDelta(hours: 1, minutes: 2, seconds: 3))
            .toString(),
        '+01:02:03',
      );
      expect(
        FixedOffset.west(TimeDelta(hours: 1, minutes: 2, seconds: 3))
            .toString(),
        '-01:02:03',
      );
    });
  });

  group('toString(…)', () {
    final dateTime = FixedOffset.east(TimeDelta(hours: 9, minutes: 30))
        .fromUtcDateTime(CDateTime(2000, 9, 1, 13, 0, 15));

    test('default', () {
      expect(dateTime.toString(), '2000-09-01T22:30:15+09:30');
      expect(
        dateTime.withTimezone(FixedOffset.zero).toString(),
        '2000-09-01T13:00:15+00:00',
      );
      final withSeconds = FixedOffset.east(TimeDelta(hours: 1, seconds: 5))
          .fromUtcDateTime(CDateTime(2000, 9, 1, 13, 0, 15));
      expect(withSeconds.toString(), '2000-09-01T14:00:20+01:00:05');
    });
    test('offset items', () {
      expect(
        dateTime.toString(const [.year(), .month(), .day(), .timezoneOffset()]),
        '20000901+09:30',
      );
      expect(
        dateTime.toString(const [.timezoneOffset(printColon: false)]),
        '+0930',
      );
      expect(
        dateTime.toString(const [.timezoneOffset(precision: .hours)]),
        '+09',
      );
    });
    test('optional offset parts', () {
      String format(TimezoneOffsetPrecision precision, TimeDelta offset) =>
          FixedOffset.east(offset)
              .fromUtcDateTime(CDateTime(2000, 9, 1))
              .toString([.timezoneOffset(precision: precision)]);

      final hms = TimeDelta(hours: 1, seconds: 5);
      final hm = TimeDelta(hours: 1, minutes: 2);
      final h = TimeDelta(hours: 1);
      expect(format(.optionalSeconds, hms), '+01:00:05');
      expect(format(.optionalSeconds, hm), '+01:02');
      expect(format(.optionalSeconds, h), '+01:00');
      expect(format(.optionalMinutesAndSeconds, hms), '+01:00:05');
      expect(format(.optionalMinutesAndSeconds, hm), '+01:02');
      expect(format(.optionalMinutesAndSeconds, h), '+01');
      expect(format(.optionalMinutes, hm), '+01:02');
      expect(format(.optionalMinutes, h), '+01');
    });
    test('zulu', () {
      final utc = dateTime.withTimezone(FixedOffset.zero);
      expect(utc.toString(const [.timezoneOffset()]), 'Z');
      expect(utc.toString(const [.timezoneOffset(allowZulu: false)]), '+00:00');
    });
  });

  group('rfc3339Format(…)', () {
    final offset = FixedOffset.east(TimeDelta(hours: 9, minutes: 30));
    final whole = offset.fromUtcDateTime(CDateTime(2000, 9, 1, 13, 0, 15));
    final fractional = whole + TimeDelta(nanos: 123456789);

    test('default', () {
      expect(
        whole.toString(ZonedDateTime.rfc3339Format()),
        '2000-09-01T22:30:15+09:30',
      );
      expect(
        fractional.toString(ZonedDateTime.rfc3339Format()),
        '2000-09-01T22:30:15.123456789+09:30',
      );
    });
    test('secondsFormat', () {
      String format(ChronoSecondsFormat secondsFormat) => fractional.toString(
        ZonedDateTime.rfc3339Format(secondsFormat: secondsFormat),
      );
      expect(format(.seconds), '2000-09-01T22:30:15+09:30');
      expect(format(.millis), '2000-09-01T22:30:15.123+09:30');
      expect(format(.micros), '2000-09-01T22:30:15.123456+09:30');
      expect(format(.nanos), '2000-09-01T22:30:15.123456789+09:30');
      expect(format(.variable), '2000-09-01T22:30:15.123456789+09:30');
      expect(
        whole.toString(ZonedDateTime.rfc3339Format(secondsFormat: .millis)),
        '2000-09-01T22:30:15.000+09:30',
      );
    });
    test('useZ', () {
      final utc = whole.withTimezone(FixedOffset.zero);
      expect(
        utc.toString(ZonedDateTime.rfc3339Format()),
        '2000-09-01T13:00:15+00:00',
      );
      expect(
        utc.toString(ZonedDateTime.rfc3339Format(useZ: true)),
        '2000-09-01T13:00:15Z',
      );
    });
  });
}
