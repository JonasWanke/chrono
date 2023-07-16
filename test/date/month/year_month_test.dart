import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(YearMonth.fromJson);

  Glados<YearMonth>().test('lengthInDays', (yearMonth) {
    expect(yearMonth.lengthInDays, inInclusiveRange(28, 31));
  });

  Glados2<YearMonth, MonthsDuration>().test('+ and -', (yearMonth, duration) {
    expect(yearMonth + duration - duration, yearMonth);
  });
  Glados<YearMonth>().test('next and previous', (yearMonth) {
    expect(yearMonth.next.previous, yearMonth);
  });
}
