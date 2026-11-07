import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  group('DateTimeDelta', () {
    Glados<DateTimeDelta>().test('unary -', (duration) {
      // ignore: unnecessary_parenthesis
      expect(-(-duration), duration);
    });
    Glados2<DateTimeDelta, ChronoDelta>().test(
      '+ and -',
      (first, second) => expect(first + second - second, first),
    );

    Glados<DateTimeDelta>().test('multiply with zero', (duration) {
      expect((duration * 0).isZero, true);
    });
    Glados2<DateTimeDelta, int>(null, any.intExcept0).test(
      '* and ~/',
      (duration, factor) => expect(duration * factor ~/ factor, duration),
    );
  });

  group('equality', () {
    Glados<CalendarDelta>().test('CalendarDelta', (duration) {
      expect(duration.toDateTimeDelta(), duration);
    });
    Glados<Months>().test('Months', (duration) {
      expect(duration.toDateTimeDelta(), duration);
    });
    Glados<Days>().test('Days', (duration) {
      expect(duration.toDateTimeDelta(), duration);
    });
    Glados<TimeDelta>().test('TimeDelta', (duration) {
      expect(duration.toDateTimeDelta(), duration);
    });
  });
}
