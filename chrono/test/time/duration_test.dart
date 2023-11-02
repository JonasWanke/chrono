import 'dart:core';
import 'dart:core' as core;

import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';
import 'package:meta/meta.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  group('Nanoseconds', () {
    _testDurationBasics<Nanoseconds>();
    Glados2<Nanoseconds, NanosecondsDuration>().test(
      '+ and -',
      (first, second) => expect(first + second - second, first),
    );
  });
  group('Microseconds', () {
    _testDurationBasics<Microseconds>();

    Glados<core.Duration>().test('fromCore', (duration) {
      expect(Microseconds.fromCore(duration).asCoreDuration, duration);
    });

    Glados2<Microseconds, MicrosecondsDuration>().test(
      '+ and -',
      (first, second) {
        expect(first + second - second, first);
      },
    );
  });
  group('Milliseconds', () {
    _testDurationBasics<Milliseconds>();
    Glados2<Milliseconds, MillisecondsDuration>().test(
      '+ and -',
      (first, second) {
        expect(first + second - second, first);
      },
    );
  });
  group('Seconds', () {
    _testDurationBasics<Seconds>();
    Glados2<Seconds, SecondsDuration>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
  });
  group('Minutes', () {
    _testDurationBasics<Minutes>();
    Glados2<Minutes, MinutesDuration>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
  });
  group('Hours', () {
    _testDurationBasics<Hours>();
    Glados2<Hours, Hours>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
  });
}

@isTest
void _testDurationBasics<T extends TimeDuration>() {
  Glados<T>().test('unary -', (duration) {
    expect(-(-duration), duration);
  });

  Glados<T>().test('multiply with zero', (duration) {
    expect((duration * 0).isZero, true);
  });
  Glados2<T, int>(null, any.intExcept0).test(
    '*, ~/, %, and remainder(…)',
    (duration, factor) {
      expect(duration * factor ~/ factor, duration);
      expect((duration * factor % factor).isZero, true);
      expect((duration * factor).remainder(factor).isZero, true);
    },
  );

  Glados<T>().test('absolute', (duration) {
    expect(duration.absolute.isNonNegative, true);
  });
}
