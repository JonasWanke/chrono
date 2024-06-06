import 'package:fixed/fixed.dart';

import 'utils.dart';

enum Rounding {
  /// Round down to the nearest integer (towards negative infinity).
  ///
  /// Corresponds to `num.floor()`.
  ///
  /// https://en.wikipedia.org/wiki/Rounding#Rounding_down
  down,

  /// Round up to the nearest integer (towards positive infinity).
  ///
  /// Corresponds to `num.ceil()`.
  ///
  /// https://en.wikipedia.org/wiki/Rounding#Rounding_up
  up,

  /// Round towards zero.
  ///
  /// Corresponds to `num.truncate()`.
  ///
  /// https://en.wikipedia.org/wiki/Rounding#Rounding_toward_zero
  towardsZero,

  /// Round to the nearest integer, with ties rounded away from zero.
  ///
  /// Corresponds to `num.round()`.
  ///
  /// https://en.wikipedia.org/wiki/Rounding#Rounding_half_away_from_zero
  nearestAwayFromZero;

  int round(num value) {
    return switch (this) {
      Rounding.down => value.floor(),
      Rounding.up => value.ceil(),
      Rounding.towardsZero => value.truncate(),
      Rounding.nearestAwayFromZero => value.round(),
    };
  }

  int roundFixed(Fixed value) => round(value.asDouble);
}
