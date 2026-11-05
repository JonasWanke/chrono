import 'package:meta/meta.dart';

import 'rounding.dart';

/// Rounds [total] / [step] to the nearest [int], per [rounding].
///
/// Unlike `rounding.round(total / step)`, this stays exact for evenly
/// divisible inputs no matter how large — `total / step` first converts to
/// `double`, which silently loses precision once `total` exceeds 2^53 (as
/// [TimeDelta]'s nanosecond totals routinely do), even when the division
/// itself is exact.
@internal
int roundDivide(int total, int step, Rounding rounding) {
  final quotient = total ~/ step;
  if (total == quotient * step) return quotient;
  return rounding.round(total / step);
}

/// Decomposes [total] (expressed in base units) into the given [units].
///
/// [baseUnitsPer] returns how many base units one of a given unit contains. The
/// largest listed unit absorbs everything above it; the smallest absorbs
/// everything below it, rounded according to [rounding].
///
/// The rounding happens *before* the decomposition, so that a rounded remainder
/// carries into the next unit up: 13 days as fortnights and weeks rounds to two
/// weeks, which is one fortnight, not zero.
///
/// Because `~/` truncates towards zero, all components share the sign of
/// [total].
@internal
Map<U, int> splitIntoUnits<U extends Object>(
  int total,
  Set<U> units,
  int Function(U unit) baseUnitsPer,
  Rounding rounding,
) {
  assert(units.isNotEmpty);

  final sorted = units.toList()
    ..sort((a, b) => baseUnitsPer(b).compareTo(baseUnitsPer(a)));
  final smallest = sorted.last;

  final values = <U, int>{};
  var remaining = roundDivide(total, baseUnitsPer(smallest), rounding);
  for (final unit in sorted.take(sorted.length - 1)) {
    final per = baseUnitsPer(unit) ~/ baseUnitsPer(smallest);
    final value = remaining ~/ per;
    values[unit] = value;
    remaining -= value * per;
  }
  values[smallest] = remaining;
  return values;
}

@internal
mixin ComparisonOperatorsFromComparable<T> implements Comparable<T> {
  bool operator <(T other) => compareTo(other) < 0;
  bool operator <=(T other) => compareTo(other) <= 0;
  bool operator >(T other) => compareTo(other) > 0;
  bool operator >=(T other) => compareTo(other) >= 0;
}

@internal
extension LetExtension<T extends Object> on T {
  R let<R>(R Function(T) block) => block(this);
}
