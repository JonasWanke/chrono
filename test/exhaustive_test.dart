import 'package:glados/glados.dart';
import 'package:plain_date_time/plain_date_time.dart';
import 'package:supernova/supernova.dart' hide Instant, Weekday;

void main() {
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
    // expect(weekday_from_days(days_from_civil(1970, 1, 1)), 4, reason: '1970-01-01 is a Thursday');

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
    // int previousWeekday = weekday_from_days(previousDaysSinceUnixEpoch);
    // assert(0 <= previousWeekday && previousWeekday <= 6);
    final startTime = Instant.now();
    for (var year = startYear; year <= endYear; ++year) {
      for (final month in PlainMonth.values) {
        final yearMonth = PlainYearMonth.from(PlainYear(year), month);
        for (final day in 1.rangeTo(yearMonth.numberOfDays)) {
          final date = PlainDate.fromYearMonthAndDayThrowing(yearMonth, day);
          final daysSinceEpoch = date.daysSinceUnixEpoch;
          expect(daysSinceEpoch, previousDaysSinceUnixEpoch + 1);

          expect(date, PlainDate.fromDaysSinceUnixEpoch(daysSinceEpoch));

          // unsigned weekday = weekday_from_days(z);
          // assert(0 <= weekday && weekday <= 6);
          // assert(weekday == next_weekday(previousWeekday));
          // assert(previousWeekday == prev_weekday(weekday));
          previousDaysSinceUnixEpoch = daysSinceEpoch;
          // previousWeekday = weekday;
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
