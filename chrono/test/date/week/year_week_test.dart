import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics<YearWeek>(jsonConverters: []);

  Glados2<YearWeek, Weeks>().test('+ and -', (yearWeek, duration) {
    expect(yearWeek + duration - duration, yearWeek);
  });
  Glados<YearWeek>().test('next and previous', (yearWeek) {
    expect(yearWeek.next.previous, yearWeek);
  });
}
