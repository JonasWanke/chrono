import 'dart:convert';
import 'dart:core' as core;
import 'dart:core';

import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';
import 'package:meta/meta.dart';

void main() {
  setChronoGladosDefaults();

  group('Instant', () {
    _testUnixEpochTimestampBasics<Instant>(
      codecs: const [InstantAsIsoStringCodec()],
    );

    Glados<Instant>().test('fromDurationSinceUnixEpoch', (timestamp) {
      expect(
        Instant.fromDurationSinceUnixEpoch(timestamp.durationSinceUnixEpoch),
        timestamp,
      );
    });

    Glados<core.DateTime>().test('core conversion', (dateTime) {
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

    Glados2<Instant, TimeDuration>().test(
      '+, -, and difference(…)',
      (timestamp, duration) {
        expect(timestamp + duration - duration, timestamp);
        expect((timestamp + duration).difference(timestamp), duration);
      },
    );
  });

  group('UnixEpochMicroseconds', () {
    _testUnixEpochTimestampBasics<UnixEpochMicroseconds>(
      codecs: const [
        UnixEpochMicrosecondsAsIsoStringCodec(),
        UnixEpochMicrosecondsAsIntCodec(),
      ],
    );

    Glados<UnixEpochMicroseconds>().test('constructor', (timestamp) {
      expect(
        UnixEpochMicroseconds(timestamp.durationSinceUnixEpoch),
        timestamp,
      );
    });

    Glados<UnixEpochMicroseconds>().test('core conversion', (timestamp) {
      expect(
        UnixEpochMicroseconds.fromCore(timestamp.asCoreDateTimeInLocalZone),
        timestamp,
      );
      expect(
        UnixEpochMicroseconds.fromCore(timestamp.asCoreDateTimeInUtc),
        timestamp,
      );
    });

    Glados<UnixEpochMicroseconds>().test('DateTime conversion', (timestamp) {
      expect(
        timestamp,
        timestamp.dateTimeInLocalZone.inLocalZone.roundToMicroseconds(),
      );
      expect(timestamp, timestamp.dateTimeInUtc.inUtc.roundToMicroseconds());
    });

    Glados2<UnixEpochMicroseconds, MicrosecondsDuration>().test(
      '+, -, and difference(…)',
      (timestamp, duration) {
        expect(timestamp + duration - duration, timestamp);
        expect((timestamp + duration).difference(timestamp), duration);
      },
    );
  });

  group('UnixEpochMilliseconds', () {
    _testUnixEpochTimestampBasics<UnixEpochMilliseconds>(
      codecs: const [
        UnixEpochMillisecondsAsIsoStringCodec(),
        UnixEpochMillisecondsAsIntCodec(),
      ],
    );

    Glados<UnixEpochMilliseconds>().test('constructor', (timestamp) {
      expect(
        UnixEpochMilliseconds(timestamp.durationSinceUnixEpoch),
        timestamp,
      );
    });

    Glados<UnixEpochMilliseconds>().test('core conversion', (timestamp) {
      expect(
        UnixEpochMilliseconds.fromCore(timestamp.asCoreDateTimeInLocalZone),
        timestamp,
      );
      expect(
        UnixEpochMilliseconds.fromCore(timestamp.asCoreDateTimeInUtc),
        timestamp,
      );
    });

    Glados<UnixEpochMilliseconds>().test('DateTime conversion', (timestamp) {
      expect(
        timestamp,
        timestamp.dateTimeInLocalZone.inLocalZone.roundToMilliseconds(),
      );
      expect(timestamp, timestamp.dateTimeInUtc.inUtc.roundToMilliseconds());
    });

    Glados2<UnixEpochMilliseconds, MillisecondsDuration>().test(
      '+, -, and difference(…)',
      (timestamp, duration) {
        expect(timestamp + duration - duration, timestamp);
        expect((timestamp + duration).difference(timestamp), duration);
      },
    );
  });

  group('UnixEpochSeconds', () {
    _testUnixEpochTimestampBasics<UnixEpochSeconds>(
      codecs: const [
        UnixEpochSecondsAsIsoStringCodec(),
        UnixEpochSecondsAsIntCodec(),
      ],
    );

    Glados<UnixEpochSeconds>().test('constructor', (timestamp) {
      expect(UnixEpochSeconds(timestamp.durationSinceUnixEpoch), timestamp);
    });

    Glados<UnixEpochSeconds>().test('core conversion', (timestamp) {
      expect(
        UnixEpochSeconds.fromCore(timestamp.asCoreDateTimeInLocalZone),
        timestamp,
      );
      expect(
        UnixEpochSeconds.fromCore(timestamp.asCoreDateTimeInUtc),
        timestamp,
      );
    });

    Glados<UnixEpochSeconds>().test('DateTime conversion', (timestamp) {
      expect(
        timestamp,
        timestamp.dateTimeInLocalZone.inLocalZone.roundToSeconds(),
      );
      expect(timestamp, timestamp.dateTimeInUtc.inUtc.roundToSeconds());
    });

    Glados2<UnixEpochSeconds, SecondsDuration>().test(
      '+, -, and difference(…)',
      (timestamp, duration) {
        expect(timestamp + duration - duration, timestamp);
        expect((timestamp + duration).difference(timestamp), duration);
      },
    );
  });
}

@isTest
void _testUnixEpochTimestampBasics<T extends UnixEpochTimestamp>({
  required List<Codec<T, dynamic>> codecs,
}) {
  // Inlines from [testDataClassBasics] because Dart doesn't support variance.
  Glados<T>().test('equality', (value) {
    expect(value == value, true);
    expect(value.compareTo(value), 0);
  });
  group('Codecs', () {
    for (final codec in codecs) {
      Glados<T>().test(codec.runtimeType.toString(), (value) {
        expect(codec.decode(codec.encode(value)), value);
      });
    }
  });
}
