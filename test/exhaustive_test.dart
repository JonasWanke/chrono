import 'package:glados/glados.dart';
import 'package:plain_date_time/plain_date_time.dart';
import 'package:supernova/supernova.dart' hide Instant, Weekday;

void main() {
  test('Exhaustive arithmetic check for chrono', () {
    // Inspired by this website, plus some extra tests:
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
    expect(
      unixEpoch.weekday,
      Weekday.thursday,
      reason: '1970-01-01 is a Thursday',
    );

    const startYear = -10000; // -1000000;
    final startDate = PlainDate.fromThrowing(
      const PlainYear(startYear),
      PlainMonth.january,
      1,
    );
    final startDateDaysSinceUnixEpoch = startDate.daysSinceUnixEpoch;

    const endYear = -startYear;
    final endDate = PlainDate.fromThrowing(
      const PlainYear(endYear),
      PlainMonth.december,
      31,
    );

    final totalNumberOfDays =
        endDate.daysSinceUnixEpoch - startDate.daysSinceUnixEpoch + 1;
    // expect(totalNumberOfDays, 730485366);

    final previousDate =
        PlainDate.fromDaysSinceUnixEpoch(startDateDaysSinceUnixEpoch - 1);
    var previous = (
      daysSinceUnixEpoch: startDateDaysSinceUnixEpoch - 1,
      dayOfYear: previousDate.dayOfYear,
      weekday: previousDate.weekday,
    );
    // expect(previous.daysSinceUnixEpoch, -365962029);
    // expect(previous.dayOfYear, TODO);
    // expect(previous.weekday, TODO);

    final startTime = Instant.now();
    for (var year = startYear; year <= endYear; ++year) {
      for (final month in PlainMonth.values) {
        final yearMonth = PlainYearMonth.from(PlainYear(year), month);
        for (final day in 1.rangeTo(yearMonth.numberOfDays)) {
          final date = PlainDate.fromYearMonthAndDayThrowing(yearMonth, day);

          final daysSinceEpoch = date.daysSinceUnixEpoch;
          expect(daysSinceEpoch, previous.daysSinceUnixEpoch + 1);
          expect(date, PlainDate.fromDaysSinceUnixEpoch(daysSinceEpoch));

          final dayOfYear = date.dayOfYear;
          expect(
            dayOfYear,
            date.month == PlainMonth.january && date.day == 1
                ? 1
                : previous.dayOfYear + 1,
          );

          final weekday = date.weekday;
          expect(previous.weekday.next, weekday);
          expect(weekday.previous, previous.weekday);

          previous = (
            daysSinceUnixEpoch: daysSinceEpoch,
            dayOfYear: dayOfYear,
            weekday: weekday,
          );
        }
      }
    }
    final endTime = Instant.now();

    print(
      'Tested $totalNumberOfDays days in ${endTime.dateTimeInUtc.difference(startTime.dateTimeInUtc)}',
    );
  });
}
