import 'package:clock/clock.dart' as cl;
import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';

import '../codec.dart';
import '../date/date.dart';
import '../date/duration.dart';
import '../instant.dart';
import '../offset/fixed.dart';
import '../offset/time_zone.dart';
import '../offset/utc.dart';
import '../parser.dart';
import '../rounding.dart';
import '../time/duration.dart';
import '../time/time.dart';
import '../utils.dart';
import '../zoned/zoned_date_time.dart';
import 'duration.dart';

/// A date and time in the ISO 8601 calendar represented using [Date] and
/// [Time], e.g., April 23, 2023, at 18:24:20.
///
/// Leap years are taken into account. However, since this class doesn't care
/// about timezones, each day is exactly 24 hours long.
///
/// This class is called `CDateTime` to avoid conflicts with `DateTime` from
/// `dart:core`.
///
/// See also:
///
/// - [Date], which represents the date part.
/// - [Time], which represents the time part.
@immutable
final class CDateTime
    with ComparisonOperatorsFromComparable<CDateTime>
    implements Comparable<CDateTime> {
  const CDateTime(this.date, this.time);
  CDateTime.fromRaw(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
    int nanoseconds = 0,
  ]) : this(
         Date.fromRaw(year, month, day),
         Time.from(hour, minute, second, nanoseconds),
       );

  /// The UNIX epoch: 1970-01-01 at 00:00.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  // TODO(JonasWanke): remove in favor of `zonedDateTime.unixEpoch`
  static final unixEpoch = Date.unixEpoch.at(Time.midnight);

  // TODO(JonasWanke): remove in favor of `zonedDateTime.fromDurationSinceUnixEpoch(…)`
  /// The date corresponding to the given duration since the [unixEpoch].
  factory CDateTime.fromDurationSinceUnixEpoch(TimeDelta sinceUnixEpoch) {
    final (days, time) = sinceUnixEpoch.toDaysAndTime();
    final date = Date.fromDaysSinceUnixEpoch(days);
    return CDateTime(date, time);
  }

  /// Creates a Chrono [CDateTime] from a Dart Core [DateTime].
  ///
  /// This uses the [DateTime.year], [DateTime.month], [DateTime.day],
  /// [DateTime.hour], etc. getters and ignores whether that [ÐateTime] is in
  /// UTC or the local timezone.
  CDateTime.fromCore(DateTime dateTime)
    : date = Date.fromCore(dateTime),
      time = Time.from(
        dateTime.hour,
        dateTime.minute,
        dateTime.second,
        dateTime.millisecond,
        dateTime.microsecond,
      );
  CDateTime.nowInLocalZone({Clock? clock})
    : this.fromCore((clock ?? cl.clock).now().toLocal());
  CDateTime.nowInUtc({Clock? clock})
    : this.fromCore((clock ?? cl.clock).now().toUtc());

  final Date date;
  final Time time;

  /// The duration since the [unixEpoch].
  // TODO(JonasWanke): remove in favor of `zonedDateTime.durationSinceUnixEpoch`
  TimeDelta get durationSinceUnixEpoch {
    return time.timeSinceMidnight +
        TimeDelta(normalDays: date.daysSinceUnixEpoch.inDays);
  }

  Instant get inLocalZone => Instant.fromCore(asCoreDateTimeInLocalZone);
  Instant get inUtc =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch);

  /// Converts the [CDateTime] into a timezone-aware [ZonedDateTime] with the
  /// provided [TimeZone] [Tz].
  @useResult
  MappedLocalTime<ZonedDateTime<Tz>> andLocalTimezone<Tz extends TimeZone<Tz>>(
    Tz tz,
  ) => tz.fromLocalDateTime(this);

  /// Converts the [CDateTime] into the timezone-aware [DateTime] of [Utc].
  @useResult
  ZonedDateTime<Utc> andUtc() =>
      ZonedDateTime.fromUtcDateTimeAndOffset(this, const Utc());

  DateTime get asCoreDateTimeInLocalZone => _getDartDateTime(isUtc: false);
  DateTime get asCoreDateTimeInUtc => _getDartDateTime(isUtc: true);
  DateTime _getDartDateTime({required bool isUtc}) {
    return (isUtc ? DateTime.utc : DateTime.new)(
      date.year.number,
      date.month.number,
      date.day,
      time.hour,
      time.minute,
      time.second,
      0,
      (time.subSecondNanos / TimeDelta.nanosPerMicrosecond).round(),
    );
  }

  CDateTime operator +(CDuration duration) {
    final compoundDuration = duration.asCompoundDuration;
    var newDate = date + compoundDuration.months + compoundDuration.days;

    final (days, newTime) = (time.timeSinceMidnight + compoundDuration.time)
        .toDaysAndTime();
    newDate += days;
    return CDateTime(newDate, newTime);
  }

  CDateTime operator -(CDuration duration) => this + (-duration);

  /// Adds the given [FixedOffset] to the current [CDateTime].
  ///
  /// This method is similar to [+], but preserves leap seconds.
  @useResult
  CDateTime addOffset(FixedOffset offset) {
    final (time, days) = this.time.overflowingAddOffset(offset);
    return CDateTime(date + days, time);
  }

  /// Subtracts the given [FixedOffset] from the current [CDateTime].
  ///
  /// This method is similar to [-], but preserves leap seconds.
  @useResult
  CDateTime subOffset(FixedOffset offset) {
    final (time, days) = this.time.overflowingSubOffset(offset);
    return CDateTime(date + days, time);
  }

  /// Returns `this - other` as days and fractional seconds.
  ///
  /// The returned [CompoundDuration]'s days and seconds are both `>= 0` or both
  /// `<= 0`. The months will always be zero.
  CompoundDuration difference(CDateTime other) {
    if (this < other) return -other.difference(this);

    var days = date.differenceInDays(other.date);
    TimeDelta timeDelta;
    if (time < other.time) {
      days -= const Days(1);
      timeDelta = time.difference(other.time) + TimeDelta(normalDays: 1);
    } else {
      timeDelta = time.difference(other.time);
    }

    return CompoundDuration(days: days, time: timeDelta);
  }

  /// Returns `this - other` as fractional seconds.
  ///
  /// The returned [CompoundDuration]'s days and seconds are both `>= 0` or both
  /// `<= 0`. The months will always be zero.
  TimeDelta timeDifference(CDateTime other) {
    final difference = this.difference(other);
    assert(difference.months.isZero);
    return difference.time + TimeDelta(normalDays: difference.days.inDays);
  }

  CDateTime roundTimeToMultipleOf(
    TimeDelta duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) => date.at(time.roundToMultipleOf(duration, rounding: rounding));

  CDateTime copyWith({Date? date, Time? time}) =>
      CDateTime(date ?? this.date, time ?? this.time);

  @override
  int compareTo(CDateTime other) {
    final result = date.compareTo(other.date);
    if (result != 0) return result;

    return time.compareTo(other.time);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CDateTime && date == other.date && time == other.time);
  }

  @override
  int get hashCode => Object.hash(date, time);

  @override
  String toString() => '${date}T$time';
}

extension RangeOfCDateTimeExtension on Range<CDateTime> {
  TimeDelta get timeDuration => end.timeDifference(start);
  CompoundDuration get compoundDuration => end.difference(start);
}

extension on TimeDelta {
  (Days, Time) toDaysAndTime() {
    var (seconds, nanos) = splitSecondsNanos();
    if (seconds == 0 && nanos.isNegative) {
      seconds = -1;
      nanos += TimeDelta.nanosPerSecond;
    }

    final days = (seconds / TimeDelta.secondsPerNormalDay).floor();
    final secondsWithinDay = seconds - days * TimeDelta.secondsPerNormalDay;
    final time = Time.fromTimeSinceMidnight(
      TimeDelta(seconds: secondsWithinDay, nanos: nanos),
    );
    return (Days(days), time);
  }
}

/// Encodes a [CDateTime] as an ISO 8601 string, e.g.,
/// “2023-04-23T18:24:20.123456789”.
class CDateTimeAsIsoStringCodec
    extends CodecAndJsonConverter<CDateTime, String> {
  const CDateTimeAsIsoStringCodec();

  @override
  String encode(CDateTime input) => input.toString();
  @override
  CDateTime decode(String encoded) => Parser.parseDateTime(encoded);
}
