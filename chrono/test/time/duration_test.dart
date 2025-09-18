import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  group('TimeDelta', () {
    Glados<TimeDelta>().test('equality', (value) {
      expect(value == value, true);
      expect(value.compareTo(value), 0);
    });

    Glados2<TimeDelta, TimeDelta>().test(
      '+ and -',
      (first, second) => expect(first + second - second, first),
    );
    Glados<TimeDelta>().test('unary -', (duration) {
      // ignore: unnecessary_parenthesis
      expect(-(-duration), duration);
    });
    Glados<TimeDelta>().test('absolute', (duration) {
      expect(duration.absolute.isNonNegative, true);
    });

    Glados<TimeDelta>().test('multiply with zero', (duration) {
      expect((duration * 0).isZero, true);
    });
    Glados2<TimeDelta, int>(null, any.intExcept0).test(
      '*, ~/, %, and remainder(…)',
      (duration, factor) {
        expect(duration * factor ~/ factor, duration);
        expect((duration * factor % factor).isZero, true);
        expect((duration * factor).remainder(factor).isZero, true);
      },
    );
  });
}
