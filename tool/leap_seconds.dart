import 'package:chrono/chrono.dart';
import 'package:supernova/supernova.dart';

import 'zone_information_compiler.dart';

/// Maximum number of leap second corrections
///
/// This must be at least 27 for leap seconds from 1972 through mid-2023.
///
/// There's a plan to discontinue leap seconds by 2035.
// TODO: Remove this limit?
const TZ_MAX_LEAPS = 50;

/// Original: `trans`, `corr`, `roll`
final leapSeconds = <LeapSecond>[];
int get leapcnt => leapSeconds.length;

/// Original: `leapadd`
void addLeapSecond(LeapSecond leapSecond) {
  if (leapcnt >= TZ_MAX_LEAPS) {
    logger.error('Too many leap seconds.');
    throw Exception('EXIT_FAILURE');
    // exit(EXIT_FAILURE);
  }
  if (leapSecond.rolling != 0 && (lo_time != min_time || hi_time != max_time)) {
    logger.error('Rolling leap seconds not supported with -r');
    throw Exception('EXIT_FAILURE');
    // exit(EXIT_FAILURE);
  }

  final index = leapSeconds.lowerBoundBy(leapSecond, (it) => it.transition);
  leapSeconds.insert(index, leapSecond);
}

@immutable
final class LeapSecond {
  const LeapSecond({
    required this.transition,
    required this.correction,
    required this.rolling,
  });

  final UnixEpochSeconds transition;
  final Seconds correction;
  // TODO: Should this be a `boolean`?
  final int rolling;
}
