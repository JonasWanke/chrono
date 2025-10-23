import 'package:meta/meta.dart';

import '../../chrono.dart';

/// The time zone with fixed offset, from UTC-23:59:59 to UTC+23:59:59.
///
/// Using the [`TimeZone`](./trait.TimeZone.html) methods
/// on a `FixedOffset` struct is the preferred way to construct
/// `DateTime<FixedOffset>` instances. See the [`east_opt`](#method.east_opt) and
/// [`west_opt`](#method.west_opt) methods for examples.
@immutable
class FixedOffset extends TimeZone<FixedOffset> implements Offset<FixedOffset> {
  /// Makes a new [FixedOffset] for the Eastern Hemisphere with given timezone
  /// difference.
  ///
  /// Negative [seconds] means the Western Hemisphere.
  ///
  /// [seconds] must be less than a day in either direction.
  @useResult
  const FixedOffset.east(int seconds) : this._(seconds);

  /// Makes a new [FixedOffset] for the Western Hemisphere with given timezone
  /// difference.
  ///
  /// Negative [seconds] means the Eastern Hemisphere.
  ///
  /// [seconds] must be less than a day in either direction.
  @useResult
  const FixedOffset.west(int seconds) : this._(-seconds);

  const FixedOffset._(this.localMinusUtcSeconds)
    : assert(
        -TimeDelta.secondsPerNormalDay < localMinusUtcSeconds &&
            localMinusUtcSeconds < TimeDelta.secondsPerNormalDay,
      );

  /// The number of seconds to add to convert from UTC to the local time.
  final int localMinusUtcSeconds;

  /// The number of seconds to add to convert from the local time to UTC.
  int get utcMinusLocalSeconds => -localMinusUtcSeconds;

  @override
  FixedOffset get timeZone => this;

  @override
  FixedOffset fix() => this;

  @override
  MappedLocalTime<FixedOffset> offsetFromLocalDateTime(CDateTime local) =>
      MappedLocalTime_Single(this);
  @override
  FixedOffset offsetFromUtcDateTime(CDateTime local) => this;

  @override
  bool operator ==(Object other) =>
      other is FixedOffset &&
      other.localMinusUtcSeconds == localMinusUtcSeconds;
  @override
  int get hashCode => localMinusUtcSeconds.hashCode;

  @override
  String toString() {
    final (sign, offset) = localMinusUtcSeconds < 0
        ? ('-', -localMinusUtcSeconds)
        : ('+', localMinusUtcSeconds);
    final (hoursRaw, minutesRaw, secondsRaw, _) = TimeDelta(
      seconds: offset,
    ).splitHoursMinutesSecondsNanos();
    final hours = hoursRaw.toString().padLeft(2, '0');
    final minutes = minutesRaw.toString().padLeft(2, '0');
    final seconds = secondsRaw.toString().padLeft(2, '0');
    return secondsRaw == 0
        ? '$sign$hours:$minutes'
        : '$sign$hours:$minutes$seconds';
  }
}
