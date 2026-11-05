import 'package:meta/meta.dart';

import '../../chrono.dart';

/// The time zone with fixed offset, from UTC-23:59:59 to UTC+23:59:59.
///
/// Using the [`TimeZone`](./trait.TimeZone.html) methods
/// on a `FixedOffset` struct is the preferred way to construct
/// `DateTime<FixedOffset>` instances. See the [`east_opt`](#method.east_opt) and
/// [`west_opt`](#method.west_opt) methods for examples.
@immutable
class const FixedOffset._unchecked(
  /// The duration to add to convert from UTC to the local time.
  final TimeDelta localMinusUtc,
) extends TimeZone<FixedOffset> implements Offset<FixedOffset> {
  /// Makes a new [FixedOffset] for the Eastern Hemisphere with given timezone
  /// difference.
  ///
  /// Negative [seconds] means the Western Hemisphere.
  ///
  /// [seconds] must be less than a day in either direction.
  factory east(TimeDelta seconds) => FixedOffset._(seconds);

  /// Makes a new [FixedOffset] for the Western Hemisphere with given timezone
  /// difference.
  ///
  /// Negative [seconds] means the Eastern Hemisphere.
  ///
  /// [seconds] must be less than a day in either direction.
  factory west(TimeDelta seconds) => FixedOffset._(-seconds);

  factory _(TimeDelta localMinusUtc) {
    assert(minOffset <= localMinusUtc && localMinusUtc <= maxOffset);
    return FixedOffset._unchecked(localMinusUtc);
  }
  static const zero = FixedOffset._unchecked(TimeDelta.raw(0, 0));

  static final minOffset = TimeDelta(normalDays: -1, nanos: 1);
  static final maxOffset = TimeDelta(normalDays: 1, nanos: -1);

  /// The duration to add to convert from the local time to UTC.
  TimeDelta get utcMinusLocal => -localMinusUtc;

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
      other is FixedOffset && other.localMinusUtc == localMinusUtc;
  @override
  int get hashCode => localMinusUtc.hashCode;

  @override
  String toString() {
    final (sign, offset) = localMinusUtc.isNegative
        ? ('-', -localMinusUtc)
        : ('+', localMinusUtc);
    final parts = offset.split({.hours, .minutes, .seconds, .nanos});
    final hours = parts.hours.toString().padLeft(2, '0');
    final minutes = parts.minutes.toString().padLeft(2, '0');
    final seconds = parts.seconds.toString().padLeft(2, '0');
    return parts.seconds == 0
        ? '$sign$hours:$minutes'
        : '$sign$hours:$minutes:$seconds';
  }
}
