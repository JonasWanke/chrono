import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  group('TimeDelta', () {
    // ignore: missing-test-assertion
    testDataClassBasics<TimeDelta>(
      preciseCodecs: [const TimeDeltaAsMapCodec()],
    );

    group('Imprecise codecs', () {
      testCodecStartingFromEncoded(const TimeDeltaAsSecondsIntCodec());
      testCodecStartingFromEncoded(const TimeDeltaAsMinutesIntCodec());
      testCodecStartingFromEncoded(const TimeDeltaAsHoursIntCodec());
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

  group('roundTo…()', () {
    test('roundToNormalWeeks', () {
      expect(TimeDelta(normalDays: 7).roundToNormalWeeks(), const Weeks(1));
      expect(TimeDelta(normalDays: 14).roundToNormalWeeks(), const Weeks(2));
      expect(TimeDelta(normalDays: -7).roundToNormalWeeks(), const Weeks(-1));
      expect(TimeDelta(normalDays: 3).roundToNormalWeeks(), const Weeks(0));
    });
    test('roundToNormalDays', () {
      expect(TimeDelta(hours: 24).roundToNormalDays(), const Days(1));
      expect(TimeDelta(hours: -48).roundToNormalDays(), const Days(-2));
    });
    test('roundToNormalYears and roundToNormalLeapYears', () {
      expect(TimeDelta(normalDays: 365).roundToNormalYears(), const Years(1));
      expect(
        TimeDelta(normalDays: 366).roundToNormalLeapYears(),
        const Years(1),
      );
    });
    test('roundToMultipleOfNormalWeeks', () {
      expect(
        TimeDelta(normalDays: 15).roundToMultipleOfNormalWeeks(const Weeks(1)),
        const Weeks(2),
      );
    });
  });
}
