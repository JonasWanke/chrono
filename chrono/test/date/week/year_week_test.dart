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
