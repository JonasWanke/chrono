import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  group('TimeDelta', () {
    testDataClassBasics<TimeDelta>(
      preciseCodecs: [const TimeDeltaAsMapCodec()],
    );

    group('Imprecise codecs', () {
      testCodecStartingFromEncoded(const TimeDeltaAsSecondsIntCodec());
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
      '* and ~/',
      (duration, factor) => expect(duration * factor ~/ factor, duration),
    );
  });
}
