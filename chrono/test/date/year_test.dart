import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics<Year>(
    jsonConverters: [
      const YearAsIsoStringJsonConverter(),
      const YearAsIntJsonConverter(),
    ],
  );

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

  test('numberOfWeeks', () {
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
      expect(Year(number).numberOfWeeks, longYears.contains(number) ? 53 : 52);
    }
  });

  Glados2<Year, Years>().test('+ and -', (year, duration) {
    expect(year + duration - duration, year);
  });
  Glados<Year>().test('next and previous', (year) {
    expect(year.next.previous, year);
  });
}
