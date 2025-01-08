import 'package:clock/clock.dart' as cl;
import 'package:clock/clock.dart';
import 'package:deranged/deranged.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:oxidized/oxidized.dart';

import '../codec.dart';
import '../date/date.dart';
import '../date/duration.dart';
import '../parser.dart';
import '../rounding.dart';
import '../time/duration.dart';
import '../time/time.dart';
import '../unix_epoch_timestamp.dart';
import '../utils.dart';
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
  static Result<CDateTime, String> fromRaw(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
    Nanoseconds? nanoseconds,
  ]) =>
      Date.fromRaw(year, month, day).andThen(
        (date) => Time.from(hour, minute, second, nanoseconds)
            .map((time) => CDateTime(date, time)),
      );

  /// The UNIX epoch: 1970-01-01 at 00:00.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static final unixEpoch = Date.unixEpoch.at(Time.midnight);

  /// The date corresponding to the given duration since the [unixEpoch].
  factory CDateTime.fromDurationSinceUnixEpoch(TimeDuration sinceUnixEpoch) {
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
          Nanoseconds.millisecond * dateTime.millisecond +
              Nanoseconds.microsecond * dateTime.microsecond,
        ).unwrap();
  CDateTime.nowInLocalZone({Clock? clock})
      : this.fromCore((clock ?? cl.clock).now().toLocal());
  CDateTime.nowInUtc({Clock? clock})
      : this.fromCore((clock ?? cl.clock).now().toUtc());

  final Date date;
  final Time time;

  /// The duration since the [unixEpoch].
  Nanoseconds get durationSinceUnixEpoch {
    return time.nanosecondsSinceMidnight +
        date.daysSinceUnixEpoch.asNormalHours;
  }

  Instant get inLocalZone => Instant.fromCore(asCoreDateTimeInLocalZone);
  Instant get inUtc =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch);

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
      time.nanoseconds.roundToMicroseconds().inMicroseconds,
    );
  }

  CDateTime operator +(CDuration duration) {
    final compoundDuration = duration.asCompoundDuration;
    var newDate = date + compoundDuration.months + compoundDuration.days;

    final (days, newTime) =
        (time.nanosecondsSinceMidnight + compoundDuration.seconds)
            .toDaysAndTime();
    newDate += days;
    return CDateTime(newDate, newTime);
  }

  CDateTime operator -(CDuration duration) => this + (-duration);

  /// Returns `this - other` as days and fractional seconds.
  ///
  /// The returned [CompoundDuration]'s days and seconds are both `>= 0` or both
  /// `<= 0`. The months will always be zero.
  CompoundDuration difference(CDateTime other) {
    if (this < other) return -other.difference(this);

    var days = date.differenceInDays(other.date);
    Nanoseconds nanoseconds;
    if (time < other.time) {
      days -= const Days(1);
      nanoseconds = time.difference(other.time) + const Days(1).asNormalHours;
    } else {
      nanoseconds = time.difference(other.time);
    }

    return CompoundDuration(days: days, seconds: nanoseconds);
  }

  /// Returns `this - other` as fractional seconds.
  ///
  /// The returned [CompoundDuration]'s days and seconds are both `>= 0` or both
  /// `<= 0`. The months will always be zero.
  Nanoseconds timeDifference(CDateTime other) {
    final difference = this.difference(other);
    assert(difference.months.isZero);
    return difference.seconds + difference.days.asNormalHours;
  }

  CDateTime roundTimeToMultipleOf(
    TimeDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      date.at(time.roundToMultipleOf(duration, rounding: rounding));

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
  Nanoseconds get timeDuration => end.timeDifference(start);
  CompoundDuration get compoundDuration => end.difference(start);
}

extension on TimeDuration {
  (Days, Time) toDaysAndTime() {
    var (seconds, nanoseconds) = splitSecondsNanos;
    if (seconds.isZero && nanoseconds.isNegative) {
      seconds = -const Seconds(1);
      nanoseconds += Nanoseconds.second;
    }

    final days = seconds.roundToNormalDays(rounding: Rounding.down);
    final secondsWithinDay = seconds - days.asNormalSeconds;
    final time =
        Time.fromTimeSinceMidnight(nanoseconds + secondsWithinDay).unwrap();
    return (days, time);
  }
}

/// Encodes a [CDateTime] as an ISO 8601 string, e.g.,
/// “2023-04-23T18:24:20.123456789”.
class CDateTimeAsIsoStringCodec
    extends CodecWithParserResult<CDateTime, String> {
  const CDateTimeAsIsoStringCodec();

  @override
  String encode(CDateTime input) => input.toString();
  @override
  Result<CDateTime, FormatException> decodeAsResult(String encoded) =>
      Parser.parseDateTime(encoded);
}
