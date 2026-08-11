import 'package:meta/meta.dart';

import 'rounding.dart';

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
  var remaining = rounding.round(total / baseUnitsPer(smallest));
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
