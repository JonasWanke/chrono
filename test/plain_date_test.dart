import 'package:glados/glados.dart';
import 'package:plain_date_time/plain_date_time.dart';
import 'package:supernova/supernova.dart';

void main() {
  Any.setDefault(any.plainYear);
  Any.setDefault(any.plainMonth);
  Any.setDefault(any.plainYearMonth);
  Any.setDefault(any.plainDate);

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
}

// ignore: avoid-top-level-members-in-tests, unreachable_from_main, TODO
extension PlainDateTimeAny on Any {
  Generator<PlainYear> get plainYear => any.int.map(PlainYear.new);
  Generator<PlainMonth> get plainMonth => any.choose(PlainMonth.values);
  Generator<PlainYearMonth> get plainYearMonth =>
      any.combine2(plainYear, plainMonth, PlainYearMonth.new);
  Generator<PlainDate> get plainDate => (random, size) {
        final yearMonth = any.plainYearMonth(random, size);
        final day =
            any.intInRange(1, yearMonth.value.numberOfDays + 1)(random, size);
        return _PlainDateShrinkable(yearMonth, day);
      };
}

class _PlainDateShrinkable implements Shrinkable<PlainDate> {
  _PlainDateShrinkable(this.yearMonth, this.day);

  final Shrinkable<PlainYearMonth> yearMonth;
  final Shrinkable<int> day;

  @override
  PlainDate get value =>
      PlainDate.fromYearMonthAndDay(yearMonth.value, day.value);

  @override
  Iterable<Shrinkable<PlainDate>> shrink() sync* {
    yield* yearMonth.shrink().map(
          (yearMonth) => _PlainDateShrinkable(
            yearMonth,
            MappedShrinkableValue(
              day,
              (it) => it.coerceAtMost(
                yearMonth.value.numberOfDays,
              ),
            ),
          ),
        );
    yield* day.shrink().map((day) => _PlainDateShrinkable(yearMonth, day));
  }
}
