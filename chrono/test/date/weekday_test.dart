import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(preciseCodecs: [const WeekdayAsIntCodec()]);

  testAll('`number` and `fromNumber(…)`', Weekday.values, (weekday) {
    final number = weekday.isoNumber;
    expect(number, inInclusiveRange(1, 7));
    expect(Weekday.fromNumber(number), weekday);
  });

  Glados2<Weekday, DaysDuration>().test('+ and -', (weekday, duration) {
    expect(weekday + duration - duration, weekday);
  });
  Glados<Weekday>().test('next and previous', (weekday) {
    expect(weekday.next.previous, weekday);
  });

  testAllPairs(
    '`untilNextOrSame(…)` and `untilPreviousOrSame(…)`',
    Weekday.values,
    (first, second) {
      final untilNextOrSame = first.untilNextOrSame(second);
      expectInRange<DaysDuration>(
        untilNextOrSame,
        const Days(0),
        const Days(6),
      );
      expect(first == second, untilNextOrSame == const Days(0));

      final untilPreviousOrSame = first.untilPreviousOrSame(second);
      expectInRange<DaysDuration>(
        untilPreviousOrSame,
        const Days(-6),
        const Days(0),
      );
      expect(first == second, untilPreviousOrSame == const Days(0));
    },
  );
}
