import 'dart:core' as core;
import 'dart:core';

import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

void main() {
  setChronoGladosDefaults();

  group('Instant', () {
    _testUnixEpochTimestampBasics(
      jsonConverters: [const InstantAsIsoStringJsonConverter()],
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

  group('UnixEpochNanoseconds', () {
    _testUnixEpochTimestampBasics<UnixEpochNanoseconds>(
      jsonConverters: [
        const UnixEpochNanosecondsAsIsoStringJsonConverter(),
        const UnixEpochNanosecondsAsIntJsonConverter(),
      ],
    );

    Glados<UnixEpochNanoseconds>().test('constructor', (timestamp) {
      expect(UnixEpochNanoseconds(timestamp.durationSinceUnixEpoch), timestamp);
    });

    Glados<core.DateTime>().test('core conversion', (dateTime) {
      expect(
        UnixEpochNanoseconds.fromCore(dateTime).asCoreDateTimeInLocalZone,
        dateTime,
      );

      final dateTimeInUtc = dateTime.toUtc();
      expect(
        dateTimeInUtc,
        UnixEpochNanoseconds.fromCore(dateTimeInUtc).asCoreDateTimeInUtc,
      );
    });

    Glados<UnixEpochNanoseconds>().test('DateTime conversion', (timestamp) {
      // TODO(JonasWanke): Add this test when conversion is no longer lossy.
      // ignore: lines_longer_than_80_chars
      // expect(timestamp, timestamp.dateTimeInLocalZone.inLocalZone.roundToNanoseconds());
      expect(timestamp, timestamp.dateTimeInUtc.inUtc.roundToNanoseconds());
    });

    Glados2<UnixEpochNanoseconds, NanosecondsDuration>().test(
      '+, -, and difference(…)',
      (timestamp, duration) {
        expect(timestamp + duration - duration, timestamp);
        expect((timestamp + duration).difference(timestamp), duration);
      },
    );
  });

  group('UnixEpochMicroseconds', () {
    _testUnixEpochTimestampBasics<UnixEpochMicroseconds>(
      jsonConverters: [
        const UnixEpochMicrosecondsAsIsoStringJsonConverter(),
        const UnixEpochMicrosecondsAsIntJsonConverter(),
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
      jsonConverters: [
        const UnixEpochMillisecondsAsIsoStringJsonConverter(),
        const UnixEpochMillisecondsAsIntJsonConverter(),
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
      jsonConverters: [
        const UnixEpochSecondsAsIsoStringJsonConverter(),
        const UnixEpochSecondsAsIntJsonConverter(),
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
  required List<JsonConverter<T, dynamic>> jsonConverters,
}) {
  // Inlines from [testDataClassBasics] because Dart doesn't support variance.
  Glados<T>().test('equality', (value) {
    expect(value == value, true);
    expect(value.compareTo(value), 0);
  });
  group('JSON converters', () {
    for (final jsonConverter in jsonConverters) {
      Glados<T>().test(jsonConverter.runtimeType.toString(), (value) {
        expect(jsonConverter.fromJson(jsonConverter.toJson(value)), value);
      });
    }
  });
}
