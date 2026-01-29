import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  group('CompoundDuration', () {
    Glados<CompoundDuration>().test('unary -', (duration) {
      // ignore: unnecessary_parenthesis
      expect(-(-duration), duration);
    });
    Glados2<CompoundDuration, CDuration>().test(
      '+ and -',
      (first, second) => expect(first + second - second, first),
    );

    Glados<CompoundDuration>().test('multiply with zero', (duration) {
      expect((duration * 0).isZero, true);
    });
    Glados2<CompoundDuration, int>(null, any.intExcept0).test(
      '* and ~/',
      (duration, factor) => expect(duration * factor ~/ factor, duration),
    );
  });

  group('equality', () {
    Glados<CalendarDuration>().test('CalendarDuration', (duration) {
      expect(duration.asCompoundDuration, duration);
    });
    Glados<MonthsDuration>().test('MonthsDuration', (duration) {
      expect(duration.asCompoundDuration, duration);
    });
    Glados<DaysDuration>().test('DaysDuration', (duration) {
      expect(duration.asCompoundDuration, duration);
    });
    Glados<TimeDelta>().test('TimeDelta', (duration) {
      expect(duration.asCompoundDuration, duration);
    });
  });
}
