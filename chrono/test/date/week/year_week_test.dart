import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  // ignore: missing-test-assertion
  testDataClassBasics<YearWeek>(testCompareTo: false, preciseCodecs: const []);

  Glados2<YearWeek, int>().test('+ and -', (yearWeek, duration) {
    expect(yearWeek + duration - duration, yearWeek);
  });
  Glados<YearWeek>().test('next and previous', (yearWeek) {
    expect(yearWeek.next.previous, yearWeek);
  });

  Glados<Date>().test('ISO week matches YearWeek with ISO config', (date) {
    final iso = date.isoYearWeek;
    final general = date.yearWeek(WeekConfig.iso);
    expect(general.weekBasedYear, iso.weekBasedYear);
    expect(general.week, iso.week);
    expect(general.dates, iso.dates);
  });

  group('WeekConfig presets', () {
    test('US weeks start on Sunday and week 1 contains January 1st', () {
      // 2023-01-01 is a Sunday, 2022-01-01 is a Saturday.
      final sunday = Date.from(const Year(2023), Month.january, 1);
      expect(sunday.yearWeek(WeekConfig.usSunday).week, 1);
      final saturday = Date.from(const Year(2022), Month.january, 1);
      expect(saturday.yearWeek(WeekConfig.usSunday).week, 1);
      expect(
        saturday.yearWeek(WeekConfig.usSunday).dates.start.weekday,
        Weekday.sunday,
      );
    });
    test('Middle East weeks start on Saturday', () {
      final date = Date.from(const Year(2022), Month.january, 1); // Saturday
      final week = date.yearWeek(WeekConfig.middleEast);
      expect(week.week, 1);
      expect(week.dates.start, date);
    });
  });

  test('comparing different configs throws', () {
    final a = YearWeek.fromRaw(2023, 10, WeekConfig.iso);
    final b = YearWeek.fromRaw(
      2023,
      10,
      WeekConfig.from(firstDay: Weekday.sunday, minDaysInFirstWeek: 1),
    );
    expect(() => a.compareTo(b), throwsArgumentError);
    expect(() => a.difference(b), throwsArgumentError);
  });

  test('invalid week reports the argument name', () {
    expect(
      () => YearWeek.fromRaw(2023, 0, WeekConfig.iso),
      throwsA(isA<RangeError>().having((e) => e.name, 'name', 'week')),
    );
  });
}
