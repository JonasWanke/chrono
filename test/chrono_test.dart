import 'dart:core';
import 'dart:core' as core;

import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

void main() {
  setChronoGladosDefaults();

  Glados<Time>().test('Time', (time) {
    _checkEquals(time);
    expect(time, Time.fromJson(time.toJson()));
  });
  Glados<DateTime>().test('DateTime', (dateTime) {
    _checkEquals(dateTime);
    expect(dateTime, DateTime.fromJson(dateTime.toJson()));
  });
  Glados<Instant>().test('Instant', (instant) {
    _checkEquals(instant);
    expect(instant, Instant.fromJson(instant.toJson()));
    expect(instant, instant.dateTimeInLocalZone.inLocalZone);
    expect(instant, instant.dateTimeInUtc.inUtc);
  });
  Glados<OrdinalDate>().test('OrdinalDate', (ordinalDate) {
    _checkEquals(ordinalDate);
    expect(ordinalDate, OrdinalDate.fromJson(ordinalDate.toJson()));
    expect(ordinalDate, ordinalDate.asDate.asOrdinalDate);
    expect(ordinalDate, ordinalDate.asWeekDate.asOrdinalDate);
  });
  Glados<core.DateTime>().test(
    'core.DateTime compatibility',
    (dateTimeInLocalZone) {
      expect(
        dateTimeInLocalZone,
        Instant.fromCore(dateTimeInLocalZone).asCoreDateTimeInLocalZone,
      );
      expect(
        dateTimeInLocalZone,
        DateTime.fromCore(dateTimeInLocalZone).asCoreDateTimeInLocalZone,
      );

      final dateTimeInUtc = dateTimeInLocalZone.toUtc();
      expect(
        dateTimeInUtc,
        Instant.fromCore(dateTimeInUtc).asCoreDateTimeInUtc,
      );
      expect(
        dateTimeInUtc,
        DateTime.fromCore(dateTimeInUtc).asCoreDateTimeInUtc,
      );
    },
  );
}

void _checkEquals<T extends Comparable<T>>(T value) {
  expect(value == value, true);
  expect(value.compareTo(value), 0);
}
