import 'package:clock/clock.dart';

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
  /// other number, a [RangeError] is thrown.
  factory Era.fromIndex(int index) {
    RangeError.checkValueInInterval(index, minIndex, maxIndex, 'index');
    return values[index - minIndex];
  }

  /// Returns the era with the given [index].
  ///
  /// The index must be 0 for Before the Common Era or 1 for Common Era. For any
  /// other number, `null` is returned.
  static Era? fromIndexOrNull(int index) =>
      minIndex <= index && index <= maxIndex ? values[index - minIndex] : null;

  factory Era.currentInLocalZone({Clock? clock}) =>
      Year.currentInLocalZone(clock: clock).era;
  factory Era.currentInUtc({Clock? clock}) =>
      Year.currentInUtc(clock: clock).era;

  static const minIndex = 0; // Era.beforeCommon.index
  static const maxIndex = 1; // Era.common.index

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == Era.currentInLocalZone(clock: clock);
  bool isCurrentInUtc({Clock? clock}) => this == Era.currentInUtc(clock: clock);

  /// The era after this one or `null`.
  Era? get next => Era.fromIndexOrNull(index + 1);

  /// The era before this one or `null`.
  Era? get previous => Era.fromIndexOrNull(index - 1);

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
