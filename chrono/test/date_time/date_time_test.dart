import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  // ignore: missing-test-assertion
  testDataClassBasics(
    preciseCodecs: const [
      CDateTimeAsStringCodec(),
      CDateTimeAsStringCodec(CDateTime.isoOrdinalFormat),
      CDateTimeAsStringCodec(CDateTime.isoWeekDateFormat),
    ],
  );

  test('unnamed constructor', () {
    expect(
      CDateTime(2023, 4, 23, 12, 34, 56, 123456789),
      CDateTime.from(Date(2023, 4, 23), Time(12, 34, 56, 123, 456, 789)),
    );
    expect(CDateTime(2023, 4, 23), Date(2023, 4, 23).atMidnight);
    expect(CDateTime(2023, 4, 23, 1, 2, 3, 1).time.subSecondNanos, 1);
  });

  Glados<CDateTime>().test('fromDurationSinceUnixEpoch', (dateTime) {
    expect(
      CDateTime.fromDurationSinceUnixEpoch(dateTime.durationSinceUnixEpoch),
      dateTime,
    );
  });

  Glados<DateTime>().test('fromCore', (dateTime) {
    expect(CDateTime.fromCore(dateTime).toCoreInLocalZone(), dateTime);

    final dateTimeInUtc = dateTime.toUtc();
    expect(dateTimeInUtc, CDateTime.fromCore(dateTimeInUtc).toCoreInUtc());
  });

  Glados3<CDateTime, Days, TimeDelta>().test('+ and -', (
    dateTime,
    daysDuration,
    timeDuration,
  ) {
    expect(
      dateTime + daysDuration + timeDuration - daysDuration - timeDuration,
      dateTime,
    );
  });

  test('difference(…)', () {
    final base = Date.from(const Year(2023), Month.october, 12).at(Time.noon);

    expect(
      (base + TimeDelta(hours: 5)).difference(base),
      TimeDelta(hours: 5).toDateTimeDelta(),
    );
    expect(
      (base + const Days(1)).difference(base),
      const Days(1).toDateTimeDelta(),
    );
    expect(
      (base + const Days(1) + TimeDelta(hours: 5)).difference(base),
      DateTimeDelta(days: const Days(1), time: TimeDelta(hours: 5)),
    );

    expect(
      (base - TimeDelta(hours: 5)).difference(base),
      TimeDelta(hours: -5).toDateTimeDelta(),
    );
    expect(
      (base - const Days(1)).difference(base),
      const Days(-1).toDateTimeDelta(),
    );
    expect(
      (base - const Days(1) - TimeDelta(hours: 5)).difference(base),
      DateTimeDelta(days: const Days(-1), time: TimeDelta(hours: -5)),
    );

    expect(
      (base + const Days(1) - TimeDelta(hours: 5)).difference(base),
      DateTimeDelta(time: TimeDelta(hours: 24 - 5)),
    );
    expect(
      (base - const Days(1) + TimeDelta(hours: 5)).difference(base),
      DateTimeDelta(time: TimeDelta(hours: -(24 - 5))),
    );
  });
}
