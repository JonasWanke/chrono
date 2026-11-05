import 'package:meta/meta.dart';

import '../chrono.dart' show TimeDelta;
import 'rounding.dart';
import 'time/duration.dart' show TimeDelta;

/// Rounds [total] / [step] to the nearest [int], per [rounding].
///
/// This only uses integer arithmetic, so it's exact for any input. Going
/// through `double` instead would silently lose precision once [total] exceeds
/// 2^53, as [TimeDelta]'s nanosecond totals routinely do.
@internal
int roundDivide(int total, int step, Rounding rounding) {
  final quotient = total ~/ step;
  final remainder = total.remainder(step).abs();
  if (remainder == 0) return quotient;

  final isNegative = (total < 0) != (step < 0);
  final awayFromZero = isNegative ? quotient - 1 : quotient + 1;
  return switch (rounding) {
    .towardsZero => quotient,
    .down => isNegative ? awayFromZero : quotient,
    .up => isNegative ? quotient : awayFromZero,
    // `remainder * 2 >= step.abs()`, without the risk of overflowing.
    .nearestAwayFromZero =>
      remainder >= step.abs() - remainder ? awayFromZero : quotient,
  };
}

/// Like [roundDivide], but for totals that may not fit in an [int].
@internal
BigInt roundDivideBig(BigInt total, BigInt step, Rounding rounding) {
  final quotient = total ~/ step;
  final remainder = total.remainder(step).abs();
  if (remainder == BigInt.zero) return quotient;

  final isNegative = (total.sign < 0) != (step.sign < 0);
  final one = BigInt.one;
  final awayFromZero = isNegative ? quotient - one : quotient + one;
  return switch (rounding) {
    .towardsZero => quotient,
    .down => isNegative ? awayFromZero : quotient,
    .up => isNegative ? quotient : awayFromZero,
    .nearestAwayFromZero =>
      remainder >= step.abs() - remainder ? awayFromZero : quotient,
  };
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
  final sorted = _sortedLargestFirst(units, baseUnitsPer);
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

/// Like [splitIntoUnits], but for totals that may not fit in an [int].
///
/// Prefer [splitIntoUnits] when [total] is known to fit, since this allocates.
@internal
Map<U, int> splitIntoUnitsBig<U extends Object>(
  BigInt total,
  Set<U> units,
  int Function(U unit) baseUnitsPer,
  Rounding rounding,
) {
  final sorted = _sortedLargestFirst(units, baseUnitsPer);
  final smallest = sorted.last;

  final values = <U, int>{};
  var remaining = roundDivideBig(
    total,
    BigInt.from(baseUnitsPer(smallest)),
    rounding,
  );
  for (final unit in sorted.take(sorted.length - 1)) {
    final per = BigInt.from(baseUnitsPer(unit) ~/ baseUnitsPer(smallest));
    final value = remaining ~/ per;
    values[unit] = value.toInt();
    remaining -= value * per;
  }
  values[smallest] = remaining.toInt();
  return values;
}

List<U> _sortedLargestFirst<U extends Object>(
  Set<U> units,
  int Function(U unit) baseUnitsPer,
) {
  assert(units.isNotEmpty);
  return units.toList()
    ..sort((a, b) => baseUnitsPer(b).compareTo(baseUnitsPer(a)));
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
