import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';
import 'package:oxidized/oxidized.dart';

import '../../utils.dart';

void main() {
  setChronoGladosDefaults();

  testDataClassBasics(const MonthNumberJsonConverter());

  testAll('`number` and `fromNumber(…)`', Month.values, (month) {
    final number = month.number;
    expect(number, inInclusiveRange(1, 12));
    expect(Month.fromNumber(number), Ok<Month, String>(month));
  });

  Glados2<Month, MonthsDuration>().test('+ and -', (month, duration) {
    expect(month + duration - duration, month);
  });
  Glados<Month>().test('next and previous', (month) {
    expect(month.next.previous, month);
  });

  testAllPairs(
    '`untilNextOrSame(…)` and `untilPreviousOrSame(…)`',
    Month.values,
    (first, second) {
      final untilNextOrSame = first.untilNextOrSame(second);
      expectInRange<MonthsDuration>(
        untilNextOrSame,
        const Months(0),
        const Months(11),
      );
      expect(first == second, untilNextOrSame == const Months(0));

      final untilPreviousOrSame = first.untilPreviousOrSame(second);
      expectInRange<MonthsDuration>(
        untilPreviousOrSame,
        const Months(-11),
        const Months(0),
      );
      expect(first == second, untilPreviousOrSame == const Months(0));
    },
  );
}
