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
    Glados2<TimeDelta, TimeDelta>().test('% and remainder(…)', (
      duration,
      divisor,
    ) {
      if (divisor.isZero) return;
      expect((duration % divisor).absolute < divisor.absolute, true);
      expect(duration.remainder(divisor).absolute < divisor.absolute, true);
    });
  });

  group('TimeUnit', () {
    test('per(…) is consistent with nanosPer', () {
      for (final smaller in TimeUnit.values) {
        for (final larger in TimeUnit.values) {
          if (larger.nanosPer < smaller.nanosPer) continue;
          expect(smaller.per(larger) * smaller.nanosPer, larger.nanosPer);
        }
      }
    });
    test('per(…) edge cases', () {
      expect(TimeUnit.nanos.per(.micros), 1000);
      expect(TimeUnit.micros.per(.millis), 1000);
      expect(TimeUnit.millis.per(.centis), 10);
      expect(TimeUnit.millis.per(.decis), 100);
      expect(TimeUnit.millis.per(.seconds), 1000);
      expect(TimeUnit.seconds.per(.minutes), 60);
      expect(TimeUnit.minutes.per(.hours), 60);
      expect(TimeUnit.hours.per(.normalDays), 24);
      expect(TimeUnit.normalDays.per(.normalWeeks), 7);
      expect(TimeUnit.seconds.per(.seconds), 1);
    });
  });

  group('totalIn(…)', () {
    test('edge cases', () {
      expect(TimeDelta(hours: 2).totalIn(.minutes), 120.0);
      expect(TimeDelta(hours: -2).totalIn(.minutes), -120.0);
      expect(TimeDelta(minutes: 90).totalIn(.hours), 1.5);
    });
  });

  group('roundTo…()', () {
    test('roundTo(…) edge cases', () {
      expect(TimeDelta(minutes: 90).roundTo(.hours), 2);
      expect(TimeDelta(minutes: 89).roundTo(.hours), 1);
    });
    test('roundToNormalDays', () {
      expect(TimeDelta(hours: 24).roundToNormalDays(), const Days(1));
      expect(TimeDelta(hours: -48).roundToNormalDays(), const Days(-2));
    });
    test('roundToMultipleOf', () {
      expect(
        TimeDelta(normalDays: 15).roundToMultipleOf(Days.week.asTime),
        TimeDelta(normalDays: 14),
      );
    });
    test('round(…, increment:) subsumes roundToMultipleOf for normalDays', () {
      expect(
        TimeDelta(normalDays: 15).round(.normalDays, increment: 7),
        TimeDelta(normalDays: 14),
      );
    });
  });

  group('isMultipleOf(…)', () {
    test('edge cases', () {
      expect(TimeDelta(minutes: 120).isMultipleOf(.hours), true);
      expect(TimeDelta(minutes: 90).isMultipleOf(.hours), false);
      expect(
        TimeDelta(minutes: 30).isMultipleOf(.minutes, increment: 15),
        true,
      );
      expect(
        TimeDelta(minutes: 20).isMultipleOf(.minutes, increment: 15),
        false,
      );
    });
    Glados2<TimeDelta, TimeUnit>().test('agrees with round(…)', (
      duration,
      unit,
    ) {
      expect(duration.isMultipleOf(unit), duration.round(unit) == duration);
    });
  });

  group('split(…)', () {
    test('empty units throws', () {
      expect(
        () => const TimeDelta.raw(1, 0).split({}),
        throwsA(isA<AssertionError>()),
      );
    });
    test('edge cases', () {
      final parts = TimeDelta(
        hours: 1,
        minutes: 2,
        seconds: 3,
        millis: 4,
      ).split({.hours, .minutes, .seconds, .millis, .micros, .nanos});
      expect(parts.hours, 1);
      expect(parts.minutes, 2);
      expect(parts.seconds, 3);
      expect(parts.millis, 4);
      expect(parts.micros, 0);
      expect(parts.nanos, 0);
    });
    test('skipping intermediate units', () {
      final parts = TimeDelta(hours: 25).split({.normalDays, .hours});
      expect(parts.normalDays, 1);
      expect(parts.hours, 1);
    });
    test('protobuf case is a direct field read', () {
      final delta = TimeDelta(seconds: 5, nanos: 6);
      expect(delta.wholeSeconds, 5);
      expect(delta.subSecondNanos, 6);
    });
    test('rounding carries into the next unit up', () {
      // 45 seconds rounds to one minute, which is zero hours.
      final parts = TimeDelta(seconds: 45).split({.hours, .minutes});
      expect(parts.hours, 0);
      expect(parts.minutes, 1);
    });
    Glados<TimeDelta>().test('hours and nanos recombine', (duration) {
      final parts = duration.split({.hours, .nanos});
      expect(TimeDelta(hours: parts.hours, nanos: parts.nanos), duration);
    });
    Glados<TimeDelta>().test('single unit rounds', (duration) {
      expect(duration.split({.hours}).hours, duration.roundTo(.hours));
    });
  });

  group('TimeParts', () {
    test('unrequested units throw', () {
      final parts = TimeDelta(hours: 1).split({.hours});
      expect(parts.hours, 1);
      expect(() => parts.minutes, throwsStateError);
      expect(parts.maybe(.minutes), null);
      expect(parts.has(.minutes), false);
      expect(parts.has(.hours), true);
      expect(parts.units, {TimeUnit.hours});
    });
    test('equality includes the requested units', () {
      expect(
        TimeDelta(hours: 1).split({.hours}),
        TimeDelta(hours: 1).split({.hours}),
      );
      expect(
        TimeDelta(hours: 1).split({.hours}),
        isNot(TimeDelta(hours: 1).split({.hours, .minutes})),
      );
    });
    test('toString() prints only requested units', () {
      expect(TimeDelta(hours: 1).split({.hours}).toString(), '1 hours');
      expect(
        TimeDelta(hours: 1, minutes: 2).split({.hours, .minutes}).toString(),
        '1 hours, 2 minutes',
      );
    });
  });
}
