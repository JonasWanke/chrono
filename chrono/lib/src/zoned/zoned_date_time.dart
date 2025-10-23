import 'package:meta/meta.dart';

import '../date/date.dart';
import '../date/duration.dart';
import '../date_time/date_time.dart';
import '../date_time/duration.dart';
import '../offset/fixed.dart';
import '../offset/time_zone.dart';
import '../offset/utc.dart';
import '../time/duration.dart';
import '../time/time.dart';

/// ISO 8601 combined date and time with a time zone.
@immutable
class ZonedDateTime<Tz extends TimeZone<Tz>> {
  /// The UTC [CDateTime].
  final CDateTime utcDateTime;

  /// Returns a view to the naive local datetime.
  CDateTime get localDateTime => utcDateTime.addOffset(offset.fix());

  /// The associated offset from UTC.
  final Offset<Tz> offset;

  /// The associated [TimeZone].
  Tz get timeZone => offset.timeZone;

  const ZonedDateTime.fromUtcDateTimeAndOffset(this.utcDateTime, this.offset);

  /// The date corresponding to the given duration since the [unixEpoch].
  static ZonedDateTime<Utc> fromDurationSinceUnixEpoch(
    TimeDelta sinceUnixEpoch,
  ) {
    final (days, time) = sinceUnixEpoch.toDaysAndTime();
    final date = Date.fromDaysSinceUnixEpoch(days);
    return ZonedDateTime.fromUtcDateTimeAndOffset(
      CDateTime(date, time),
      const Utc(),
    );
  }

  /// The UNIX epoch: 1970-01-01 at 00:00.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static final unixEpoch = Date.unixEpoch.at(Time.midnight).andUtc();

  @useResult
  Date get date => localDateTime.date;

  /// Returns the number of non-leap seconds since January 1, 1970 0:00:00 UTC
  /// (aka "UNIX timestamp").
  @useResult
  TimeDelta get durationSinceUnixEpoch =>
      utcDateTime.date.daysSinceUnixEpoch.asTime +
      utcDateTime.time.timeSinceMidnight;

  /// Changes the associated time zone.
  ///
  /// The returned [ZonedDateTime] references the same instant of time from
  /// the perspective of the provided time zone.
  @useResult
  ZonedDateTime<Tz2> withTimezone<Tz2 extends TimeZone<Tz2>>(Tz2 tz) =>
      tz.fromUtcDateTime(utcDateTime);

  /// Fix the offset from UTC to its current value, dropping the associated
  /// timezone information.
  ///
  /// This it useful for converting a generic `ZonedDateTime<Tz extends
  /// Timezone>` to `DateTime<FixedOffset>`.
  @useResult
  ZonedDateTime<FixedOffset> toFixedOffset() => withTimezone(offset.fix());

  /// Turn this `DateTime` into a `DateTime<Utc>`, dropping the offset and associated timezone
  /// information.
  @useResult
  ZonedDateTime<Utc> toUtc() =>
      ZonedDateTime.fromUtcDateTimeAndOffset(utcDateTime, const Utc());

  ZonedDateTime<Tz> operator +(CDuration duration) =>
      ZonedDateTime.fromUtcDateTimeAndOffset(utcDateTime + duration, offset);
  ZonedDateTime<Tz> operator -(CDuration duration) => this + (-duration);

  // TODO(JonasWanke): more arithmetic
  /// Subtracts another `DateTime` from the current date and time.
  @useResult
  TimeDelta timeDifference<Tz2 extends TimeZone<Tz2>>(
    ZonedDateTime<Tz2> other,
  ) => utcDateTime.timeDifference(other.utcDateTime);

  /// Set the time to a new fixed time on the existing date.
  @useResult
  MappedLocalTime<ZonedDateTime<Tz>> withTime(Time time) =>
      timeZone.fromLocalDateTime(localDateTime.date.at(time));

  @override
  bool operator ==(Object other) {
    return other is ZonedDateTime<Tz> &&
        utcDateTime == other.utcDateTime &&
        offset == other.offset;
  }

  @override
  int get hashCode => Object.hash(utcDateTime, offset);

  @override
  String toString() => '$localDateTime $offset';
}

extension on TimeDelta {
  (Days, Time) toDaysAndTime() {
    var (seconds, nanos) = splitSecondsNanos();
    if (seconds == 0 && nanos.isNegative) {
      seconds = -1;
      nanos += TimeDelta.nanosPerSecond;
    }

    final days = seconds ~/ TimeDelta.secondsPerNormalDay;
    final secondsWithinDay = seconds - days * TimeDelta.secondsPerNormalDay;
    final time = Time.fromTimeSinceMidnight(
      TimeDelta(seconds: secondsWithinDay, nanos: nanos),
    ).unwrap();
    return (Days(days), time);
  }
}
