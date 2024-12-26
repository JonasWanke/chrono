import 'package:clock/clock.dart';
import 'package:oxidized/oxidized.dart';

import '../utils.dart';
import 'year.dart';

/// A month in the ISO 8601 calendar, e.g., April.
enum Era
    with ComparisonOperatorsFromComparable<Era>
    implements Comparable<Era> {
  beforeCommon,
  common;

  /// Returns the era with the given [index].
  ///
  /// The index must be 0 for Before the Common Era or 1 for Common Era. For any
  /// other number, an error is returned.
  static Result<Era, String> fromIndex(int index) {
    if (index < minIndex || index > maxIndex) {
      return Err('Invalid era index: $index');
    }
    return Ok(values[index - minIndex]);
  }

  static Era currentInLocalZone({Clock? clock}) =>
      Year.currentInLocalZone(clock: clock).era;
  static Era currentInUtc({Clock? clock}) =>
      Year.currentInUtc(clock: clock).era;

  static const minIndex = 0; // Era.beforeCommon.index
  static const maxIndex = 1; // Era.common.index

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == Era.currentInLocalZone(clock: clock);
  bool isCurrentInUtc({Clock? clock}) => this == Era.currentInUtc(clock: clock);

  /// The era after this one or `null`.
  Era? get next => fromIndex(index + 1).unwrapOrNull();

  /// The era before this one or `null`.
  Era? get previous => fromIndex(index - 1).unwrapOrNull();

  @override
  int compareTo(Era other) => index.compareTo(other.index);

  @override
  String toString() {
    return switch (this) {
      Era.beforeCommon => 'Before the Common Era',
      Era.common => 'Common Era',
    };
  }
}
