import 'package:chrono/chrono.dart';
import 'package:glados/glados.dart';
import 'package:meta/meta.dart';

import '../utils.dart';

void main() {
  setChronoGladosDefaults();

  group('CompoundDaysDuration', () {
    _testDurationBasics<CompoundDaysDuration>();
    Glados2<CompoundDaysDuration, DaysDuration>().test(
      '+ and -',
      (first, second) => expect(first + second - second, first),
    );
  });

  group('Months', () {
    _testDurationBasics<Months>();
    Glados2<Months, MonthsDuration>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
  });
  group('Years', () {
    _testDurationBasics<Years>();
    Glados2<Years, Years>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
  });

  group('Days', () {
    _testDurationBasics<Days>();
    Glados2<Days, FixedDaysDuration>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
  });
  group('Weeks', () {
    _testDurationBasics<Weeks>();
    Glados2<Weeks, Weeks>().test('+ and -', (first, second) {
      expect(first + second - second, first);
    });
  });
}

@isTest
void _testDurationBasics<T extends DaysDuration>() {
  Glados<T>().test('unary -', (duration) => expect(-(-duration), duration));

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
}
