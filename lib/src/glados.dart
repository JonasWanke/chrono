import 'dart:math' as math;

import 'package:fixed/fixed.dart';
import 'package:glados/glados.dart';

import 'instant.dart';
import 'period_time.dart';
import 'plain_date.dart';
import 'plain_date_time.dart';
import 'plain_month.dart';
import 'plain_ordinal_date.dart';
import 'plain_time.dart';
import 'plain_week_date.dart';
import 'plain_year.dart';
import 'plain_year_month.dart';
import 'plain_year_week.dart';
import 'weekday.dart';

void setPlainDateTimeGladosDefaults() {
  Any.setDefault(any.instant);
  Any.setDefault(any.plainDate);
  Any.setDefault(any.plainDateTime);
  Any.setDefault(any.plainMonth);
  Any.setDefault(any.plainTime);
  Any.setDefault(any.plainOrdinalDate);
  Any.setDefault(any.plainWeekDate);
  Any.setDefault(any.plainYear);
  Any.setDefault(any.plainYearMonth);
  Any.setDefault(any.plainYearWeek);
  Any.setDefault(any.weekday);
}

extension PlainDateTimeAny on Any {
  Generator<Instant> get instant => plainDateTime.map((it) => it.inUtc);
  Generator<PlainDate> get plainDate {
    return simple(
      generate: (random, size) {
        final yearMonth = plainYearMonth(random, size);
        final day =
            intInRange(1, yearMonth.value.lengthInDays.value + 1)(random, size);
        return (yearMonth, day);
      },
      shrink: (input) sync* {
        final (yearMonth, day) = input;
        yield* yearMonth.shrink().map((yearMonth) {
          final actualDay = day.value <= yearMonth.value.lengthInDays.value
              ? day
              : day.shrink().firstWhere(
                    (it) => it.value <= yearMonth.value.lengthInDays.value,
                  );
          return (yearMonth, actualDay);
        });
        yield* day.shrink().map((it) => (yearMonth, it));
      },
    ).map(
      (it) => PlainDate.fromYearMonthAndDayUnchecked(it.$1.value, it.$2.value),
    );
  }

  Generator<PlainDateTime> get plainDateTime =>
      combine2(plainDate, plainTime, PlainDateTime.new);
  Generator<PlainMonth> get plainMonth => choose(PlainMonth.values);
  Generator<PlainTime> get plainTime {
    return combine4(
      intInRange(0, 24),
      intInRange(0, 60),
      intInRange(0, 60),
      _fraction,
      PlainTime.fromUnchecked,
    );
  }

  Generator<PlainOrdinalDate> get plainOrdinalDate {
    return simple(
      generate: (random, size) {
        final year = plainYear(random, size);
        final day =
            intInRange(1, year.value.lengthInDays.value + 1)(random, size);
        return (year, day);
      },
      shrink: (input) sync* {
        final (year, day) = input;
        yield* year.shrink().map((year) {
          final actualDay = day.value <= year.value.lengthInDays.value
              ? day
              : day.shrink().firstWhere(
                    (it) => it.value <= year.value.lengthInDays.value,
                  );
          return (year, actualDay);
        });
        yield* day.shrink().map((it) => (year, it));
      },
    ).map(
      (it) => PlainOrdinalDate.fromUnchecked(it.$1.value, it.$2.value),
    );
  }

  Generator<PlainWeekDate> get plainWeekDate =>
      combine2(plainYearWeek, weekday, PlainWeekDate.new);
  Generator<PlainYear> get plainYear => this.int.map(PlainYear.new);
  Generator<PlainYearMonth> get plainYearMonth =>
      combine2(plainYear, plainMonth, PlainYearMonth.new);
  Generator<PlainYearWeek> get plainYearWeek {
    return simple(
      generate: (random, size) {
        final weekBasedYear = plainYear(random, size);
        final week =
            intInRange(1, weekBasedYear.value.numberOfWeeks + 1)(random, size);
        return (weekBasedYear, week);
      },
      shrink: (input) sync* {
        final (weekBasedYear, week) = input;
        yield* weekBasedYear.shrink().map((weekBasedYear) {
          final actualWeek = week.value <= weekBasedYear.value.numberOfWeeks
              ? week
              : week.shrink().firstWhere(
                    (it) => it.value <= weekBasedYear.value.numberOfWeeks,
                  );
          return (weekBasedYear, actualWeek);
        });
        yield* week.shrink().map((it) => (weekBasedYear, it));
      },
    ).map((it) => PlainYearWeek.fromUnchecked(it.$1.value, it.$2.value));
  }

  Generator<Weekday> get weekday => choose(Weekday.values);

  Generator<FractionalSeconds> get _fraction {
    return simple(
      generate: (random, size) {
        final scale = positiveInt(random, math.log(size).ceil()).value;
        final minorUnits = bigIntInRange(
          BigInt.zero,
          BigInt.from(10).pow(scale),
        )(random, size)
            .value;
        return FractionalSeconds(Fixed.fromBigInt(minorUnits, scale: scale));
      },
      shrink: (input) sync* {
        if (input.isPositive) {
          yield FractionalSeconds(Fixed.fromBigInt(
            input.value.minorUnits - BigInt.one,
            scale: input.value.scale,
          ));
        }
        if (input.value.scale > 1) {
          yield FractionalSeconds(Fixed.fromBigInt(
            input.value.minorUnits ~/ BigInt.from(10),
            scale: input.value.scale - 1,
          ));
        }
      },
    );
  }
}
