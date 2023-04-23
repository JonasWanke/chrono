import 'dart:math' as math;

import 'package:fixed/fixed.dart';
import 'package:glados/glados.dart';
import 'package:plain_date_time/plain_date_time.dart';

void main() {
  Any.setDefault(any.plainYear);
  Any.setDefault(any.plainMonth);
  Any.setDefault(any.plainYearMonth);
  Any.setDefault(any.plainDate);
  Any.setDefault(any.plainTime);
  Any.setDefault(any.plainDateTime);
  Any.setDefault(any.instant);

  Glados<PlainYear>().test('PlainYear', (year) {
    expect(year, PlainYear.fromJson(year.toJson()));
  });
  // TODO: PlainMonth
  Glados<PlainYearMonth>().test('PlainYearMonth', (year) {
    expect(year, PlainYearMonth.fromJson(year.toJson()));
  });
  Glados<PlainDate>().test('PlainDate', (year) {
    expect(year, PlainDate.fromJson(year.toJson()));
  });
  Glados<PlainTime>().test('PlainTime', (year) {
    expect(year, PlainTime.fromJson(year.toJson()));
  });
  Glados<PlainDateTime>().test('PlainDateTime', (year) {
    expect(year, PlainDateTime.fromJson(year.toJson()));
  });
  Glados<Instant>().test('Instant', (year) {
    expect(year, Instant.fromJson(year.toJson()));
  });
}

// ignore: avoid-top-level-members-in-tests, unreachable_from_main, TODO
extension PlainDateTimeAny on Any {
  Generator<PlainYear> get plainYear => this.int.map(PlainYear.new);
  Generator<PlainMonth> get plainMonth => choose(PlainMonth.values);
  Generator<PlainYearMonth> get plainYearMonth =>
      combine2(plainYear, plainMonth, PlainYearMonth.new);
  Generator<PlainDate> get plainDate {
    return simple(
      generate: (random, size) {
        final yearMonth = plainYearMonth(random, size);
        final day =
            intInRange(1, yearMonth.value.numberOfDays + 1)(random, size);
        return (yearMonth, day);
        // return PlainDate.fromYearMonthAndDay(yearMonth, day);
      },
      shrink: (input) sync* {
        final (yearMonth, day) = input;
        yield* yearMonth.shrink().map((yearMonth) {
          final actualDay = day.value <= yearMonth.value.numberOfDays
              ? day
              : day
                  .shrink()
                  .firstWhere((it) => it.value <= yearMonth.value.numberOfDays);
          return (yearMonth, actualDay);
        });
        yield* day.shrink().map((it) => (yearMonth, it));
      },
    ).map((it) => PlainDate.fromYearMonthAndDay(it.$1.value, it.$2.value));
  }

  Generator<PlainTime> get plainTime => combine4(
        intInRange(0, 24),
        intInRange(0, 60),
        intInRange(0, 60),
        _fraction,
        PlainTime.new,
      );
  Generator<Fixed> get _fraction => simple(
        generate: (random, size) {
          final scale = positiveInt(random, math.log(size).ceil()).value;
          final minorUnits = bigIntInRange(
            BigInt.zero,
            BigInt.from(10).pow(scale),
          )(random, size)
              .value;
          return Fixed.fromBigInt(minorUnits, scale: scale);
        },
        shrink: (input) sync* {
          if (input.isPositive) {
            yield Fixed.fromBigInt(
              input.minorUnits - BigInt.one,
              scale: input.scale,
            );
          }
          if (input.scale > 1) {
            yield Fixed.fromBigInt(
              input.minorUnits ~/ BigInt.from(10),
              scale: input.scale - 1,
            );
          }
        },
      );
  Generator<PlainDateTime> get plainDateTime =>
      combine2(plainDate, plainTime, PlainDateTime.new);
  Generator<Instant> get instant => plainDateTime.map((it) => it.inUtc);
}
