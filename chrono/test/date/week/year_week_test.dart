import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  // ignore: missing-test-assertion
  testDataClassBasics<YearWeek>(testCompareTo: false, preciseCodecs: const []);

  Glados<YearWeek>(any.isoYearWeek)
      .test(const YearWeekAsIsoStringCodec().runtimeType.toString(), (value) {
        const codec = YearWeekAsIsoStringCodec();
        expect(codec.decode(codec.encode(value)), value);
      });
  test('ISO codec rejects other configs', () {
    final week = YearWeek(2023, 10, WeekConfig.usSunday);
    expect(
      () => const YearWeekAsIsoStringCodec().encode(week),
      throwsArgumentError,
    );
  });
  test('ISO toString', () {
    expect(YearWeek(2023, 6, .iso).toString(), '2023-W06');
  });

  Glados2<YearWeek, int>().test('+ and -', (yearWeek, duration) {
    expect(yearWeek + duration - duration, yearWeek);
  });
  Glados<YearWeek>().test('next and previous', (yearWeek) {
    expect(yearWeek.next.previous, yearWeek);
  });

  Glados<Year>().test('ISO week 1 starts on Monday and contains January 4th', (
    year,
  ) {
    final dates = year.weeks(.iso).start.dates;
    expect(dates.start.weekday, Weekday.monday);
    expect(dates.contains(Date.from(year, Month.january, 4)), true);
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

  Glados2<YearWeek, int>().test('differenceInWeeks', (yearWeek, weeks) {
    expect((yearWeek + weeks).differenceInWeeks(yearWeek), weeks);
  });

  Glados2<YearWeek, Weekday>().test('dateOn', (yearWeek, weekday) {
    final date = yearWeek.dateOn(weekday);
    expect(date.weekday, weekday);
    expect(yearWeek.dates.contains(date), true);
    expect(date.yearWeek(yearWeek.config), yearWeek);
  });

  test('comparing different configs throws', () {
    final a = YearWeek(2023, 10, WeekConfig.iso);
    final b = YearWeek(
      2023,
      10,
      WeekConfig.from(firstDay: Weekday.sunday, minDaysInFirstWeek: 1),
    );
    expect(() => a.compareTo(b), throwsArgumentError);
    expect(() => a.differenceInWeeks(b), throwsArgumentError);
  });

  test('invalid week reports the argument name', () {
    expect(
      () => YearWeek(2023, 0, WeekConfig.iso),
      throwsA(isA<RangeError>().having((e) => e.name, 'name', 'week')),
    );
  });
}
