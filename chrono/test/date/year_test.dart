import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  // ignore: missing-test-assertion
  testDataClassBasics<Year>(
    preciseCodecs: const [YearAsIsoStringCodec(), YearAsIntCodec()],
  );

  Glados2<Year, Month>().test('atMonth', (year, month) {
    expect(year.atMonth(month), YearMonth.from(year, month));
  });
  test('atOrdinalDay', () {
    expect(const Year(2023).atOrdinalDay(113), Date(2023, 4, 23));
    expect(const Year(2024).atOrdinalDay(366), Date(2024, 12, 31));
    expect(() => const Year(2023).atOrdinalDay(366), throwsRangeError);
    expect(() => const Year(2023).atOrdinalDay(0), throwsRangeError);
  });
  Glados2<Date, Weekday>().test('atWeekNumber', (date, firstDay) {
    expect(
      date.year.atWeekNumber(
        date.weekNumberStartingOn(firstDay),
        date.weekday,
        firstDay: firstDay,
      ),
      date,
    );
  });
  test('atWeekNumber known values', () {
    // 2023-01-01 is a Sunday: %U week 1 starts there, %W week 1 on January 2.
    expect(
      const Year(2023).atWeekNumber(1, .sunday, firstDay: .sunday),
      Date(2023, 1, 1),
    );
    expect(
      const Year(2023).atWeekNumber(1, .monday, firstDay: .monday),
      Date(2023, 1, 2),
    );
    expect(
      const Year(2023).atWeekNumber(0, .sunday, firstDay: .monday),
      Date(2023, 1, 1),
    );
    expect(
      () => const Year(2023).atWeekNumber(0, .monday, firstDay: .sunday),
      throwsRangeError,
    );
  });
  test('atWeek', () {
    expect(
      const Year(2023).atWeek(16, .iso),
      YearWeek.from(const Year(2023), 16, .iso),
    );
    expect(() => const Year(2023).atWeek(53, .iso), throwsRangeError);
  });

  Glados<Year>().test('isLeapYear and isCommonYear', (year) {
    expect(year.isCommonYear, !year.isLeapYear);
  });
  test('isLeapYear', () {
    expect(const Year(1600).isLeapYear, true);
    expect(const Year(1700).isLeapYear, false);
    expect(const Year(1800).isLeapYear, false);
    expect(const Year(1900).isLeapYear, false);
    expect(const Year(2000).isLeapYear, true);
    expect(const Year(2004).isLeapYear, true);
    expect(const Year(2008).isLeapYear, true);
    expect(const Year(2012).isLeapYear, true);
    expect(const Year(2016).isLeapYear, true);
    expect(const Year(2020).isLeapYear, true);
    expect(const Year(2024).isLeapYear, true);
    expect(const Year(2100).isLeapYear, false);
  });

  test('numberOfIsoWeeks', () {
    // https://en.wikipedia.org/wiki/ISO_week_date#Weeks_per_year
    final longYears = {
      //
      004, 009, 015, 020, 026,
      032, 037, 043, 048, 054,
      060, 065, 071, 076, 082,
      088, 093, 099,
      105, 111, 116, 122,
      128, 133, 139, 144, 150,
      156, 161, 167, 172, 178,
      184, 189, 195,
      201, 207, 212, 218,
      224, 229, 235, 240, 246,
      252, 257, 263, 268, 274,
      280, 285, 291, 296,
      303, 308, 314,
      320, 325, 331, 336, 342,
      348, 353, 359, 364, 370,
      376, 381, 387, 392, 398,
    };

    for (var number = 0; number < 400; number++) {
      expect(
        Year(number).numberOfWeeks(.iso),
        longYears.contains(number) ? 53 : 52,
      );
    }
  });

  Glados2<Year, int>().test('+ and -', (year, duration) {
    expect(year + duration - duration, year);
  });
  Glados<Year>().test('next and previous', (year) {
    expect(year.next.previous, year);
  });
}
