import 'package:chrono/chrono.dart';
import 'package:deranged/deranged.dart';
import 'package:glados/glados.dart';

void main() {
  test('Exhaustive arithmetic check for chrono', () {
    // Inspired by this website, plus some extra tests:
    // https://howardhinnant.github.io/date_algorithms.html#Yes,%20but%20how%20do%20you%20know%20this%20all%20really%20works?

    const unixEpoch = Date.unixEpoch;
    expect(
      unixEpoch.daysSinceUnixEpoch,
      const Days(0),
      reason: '1970-01-01 is day 0',
    );
    expect(
      Date.fromDaysSinceUnixEpoch(const Days(0)),
      unixEpoch,
      reason: '1970-01-01 is day 0',
    );
    expect(
      unixEpoch.weekday,
      Weekday.thursday,
      reason: '1970-01-01 is a Thursday',
    );

    const startYear = Year(-10000); // Year(-1000000);
    final startDate = startYear.dates.start;
    final startDateDaysSinceUnixEpoch = startDate.daysSinceUnixEpoch;

    final endYear = Year(-startYear.number);
    final endDate = endYear.dates.endInclusive;

    final totalNumberOfDays =
        endDate.daysSinceUnixEpoch -
        startDate.daysSinceUnixEpoch +
        const Days(1);
    // expect(totalNumberOfDays, 730485366);

    final previousDate = Date.fromDaysSinceUnixEpoch(
      startDateDaysSinceUnixEpoch - const Days(1),
    );
    var previous = (
      daysSinceUnixEpoch: startDateDaysSinceUnixEpoch - const Days(1),
      dayOfYear: previousDate.dayOfYear,
      weekday: previousDate.weekday,
    );
    // expect(previous.daysSinceUnixEpoch, -365962029);
    // expect(previous.dayOfYear, `TODO`);
    // expect(previous.weekday, `TODO`);

    final startTime = Instant.now();
    for (var year = startYear; year <= endYear; year += const Years(1)) {
      for (final date in year.dates.iter) {
        final daysSinceEpoch = date.daysSinceUnixEpoch;
        expect(daysSinceEpoch, previous.daysSinceUnixEpoch + const Days(1));
        expect(date, Date.fromDaysSinceUnixEpoch(daysSinceEpoch));

        final dayOfYear = date.dayOfYear;
        expect(
          dayOfYear,
          date.month == Month.january && date.day == 1
              ? 1
              : previous.dayOfYear + 1,
        );
        expect(date, Date.fromYearAndOrdinal(year, dayOfYear));

        final weekday = date.weekday;
        expect(previous.weekday.next, weekday);
        expect(weekday.previous, previous.weekday);
        expect(date, Date.fromIsoYearWeekAndWeekday(date.isoYearWeek, weekday));

        previous = (
          daysSinceUnixEpoch: daysSinceEpoch,
          dayOfYear: dayOfYear,
          weekday: weekday,
        );
      }
    }
    final endTime = Instant.now();

    print(
      'Tested $totalNumberOfDays days in ${endTime.asCoreDateTimeInUtc.difference(startTime.asCoreDateTimeInUtc)}',
    );
  });
}
