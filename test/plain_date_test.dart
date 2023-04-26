import 'package:glados/glados.dart';
import 'package:plain_date_time/plain_date_time.dart';
import 'package:supernova/supernova.dart' hide Instant;

void main() {
  setPlainDateTimeGladosDefaults();

  Glados<PlainYear>().test('PlainYear', (year) {
    expect(year, PlainYear.fromJson(year.toJson()));
  });
  Glados<PlainMonth>().test('PlainMonth', (month) {
    expect(month, PlainMonth.fromJson(month.toJson()));
  });
  Glados<PlainYearMonth>().test('PlainYearMonth', (yearMonth) {
    expect(yearMonth, PlainYearMonth.fromJson(yearMonth.toJson()));
  });
  Glados<PlainDate>().test('PlainDate', (date) {
    expect(date, PlainDate.fromJson(date.toJson()));
    expect(date, PlainDate.fromDaysSinceUnixEpoch(date.daysSinceUnixEpoch));
  });
  Glados<PlainTime>().test('PlainTime', (timet) {
    expect(timet, PlainTime.fromJson(timet.toJson()));
  });
  Glados<PlainDateTime>().test('PlainDateTime', (dateTime) {
    expect(dateTime, PlainDateTime.fromJson(dateTime.toJson()));
  });
  Glados<Instant>().test('Instant', (instant) {
    expect(instant, Instant.fromJson(instant.toJson()));
    expect(instant, instant.plainDateTimeInLocalZone.inLocalZone);
    expect(instant, instant.plainDateTimeInUtc.inUtc);
  });
  Glados<Weekday>().test('Weekday', (weekday) {
    expect(weekday, Weekday.fromJson(weekday.toJson()));
  });
  Glados<DateTime>().test('DateTime compatibility', (dateTimeInLocalZone) {
    expect(
      dateTimeInLocalZone,
      Instant.fromDateTime(dateTimeInLocalZone).dateTimeInLocalZone,
    );
    expect(
      dateTimeInLocalZone,
      PlainDateTime.fromDateTime(dateTimeInLocalZone).dateTimeInLocalZone,
    );

    final dateTimeInUtc = dateTimeInLocalZone.toUtc();
    expect(dateTimeInUtc, Instant.fromDateTime(dateTimeInUtc).dateTimeInUtc);
    expect(
      dateTimeInUtc,
      PlainDateTime.fromDateTime(dateTimeInUtc).dateTimeInUtc,
    );
  });

  test('Exhaustive arithmetic check for chrono', () {
    // https://howardhinnant.github.io/date_algorithms.html#Yes,%20but%20how%20do%20you%20know%20this%20all%20really%20works?
    final unixEpoch =
        PlainDate.fromThrowing(const PlainYear(1970), PlainMonth.january, 1);
    expect(
      unixEpoch.daysSinceUnixEpoch,
      0,
      reason: '1970-01-01 is day 0',
    );
    expect(
      PlainDate.fromDaysSinceUnixEpoch(0),
      unixEpoch,
      reason: '1970-01-01 is day 0',
    );

    const startYear = -100000; // -1000000;
    final startDate = PlainDate.fromThrowing(
      const PlainYear(startYear),
      PlainMonth.january,
      1,
    );
    const endYear = -startYear;
    final endDate = PlainDate.fromThrowing(
      const PlainYear(endYear),
      PlainMonth.december,
      31,
    );

    var previousDaysSinceUnixEpoch = startDate.daysSinceUnixEpoch - 1;
    expect(previousDaysSinceUnixEpoch, lessThan(0));
    final startTime = Instant.now();
    for (var year = startYear; year <= endYear; ++year) {
      for (final month in PlainMonth.values) {
        final yearMonth = PlainYearMonth.from(PlainYear(year), month);
        for (final day in 1.rangeTo(yearMonth.numberOfDays)) {
          final date = PlainDate.fromYearMonthAndDayThrowing(yearMonth, day);
          final daysSinceEpoch = date.daysSinceUnixEpoch;
          expect(daysSinceEpoch, previousDaysSinceUnixEpoch + 1);

          expect(date, PlainDate.fromDaysSinceUnixEpoch(daysSinceEpoch));

          previousDaysSinceUnixEpoch = daysSinceEpoch;
        }
      }
    }

    final totalNumberOfDays =
        endDate.daysSinceUnixEpoch - startDate.daysSinceUnixEpoch + 1;

    final endTime = Instant.now();
    print(
      'Tested $totalNumberOfDays days in ${endTime.dateTimeInUtc.difference(startTime.dateTimeInUtc)}',
    );
  });
}
