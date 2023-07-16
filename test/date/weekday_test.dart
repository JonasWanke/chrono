import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';
import 'package:oxidized/oxidized.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  testAll('`number` and `fromNumber(…)`', Weekday.values, (weekday) {
    final number = weekday.number;
    expect(number, inInclusiveRange(1, 7));
    expect(Weekday.fromNumber(number), Ok<Weekday, String>(weekday));
  });

  Glados<Weekday>().test('next and previous', (weekday) {
    expect(weekday.next.previous, weekday);
  });
  Glados2<Weekday, FixedDaysDuration>().test('+ and -', (weekday, duration) {
    expect(weekday + duration - duration, weekday);
  });

  testAllPairs(
    '`untilNextOrSame(…)` and `untilPreviousOrSame(…)`',
    Weekday.values,
    (first, second) {
      final untilNextOrSame = first.untilNextOrSame(second);
      expectInRange<FixedDaysDuration>(
        untilNextOrSame,
        const Days(0),
        const Days(6),
      );
      expect(first == second, untilNextOrSame == const Days(0));

      final untilPreviousOrSame = first.untilPreviousOrSame(second);
      expectInRange<FixedDaysDuration>(
        untilPreviousOrSame,
        const Days(-6),
        const Days(0),
      );
      expect(first == second, untilPreviousOrSame == const Days(0));
    },
  );
}
