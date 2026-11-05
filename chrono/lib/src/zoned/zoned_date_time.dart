import 'package:meta/meta.dart';

import '../date/date.dart';
import '../date/duration.dart';
import '../date_time/date_time.dart';
import '../date_time/duration.dart';
import '../format/format.dart';
import '../format/formatter.dart';
import '../format/parser.dart';
import '../offset/fixed.dart';
import '../offset/time_zone.dart';
import '../offset/utc.dart';
import '../time/duration.dart';
import '../time/time.dart';

/// ISO 8601 combined date and time with a time zone.
@immutable
class const ZonedDateTime<Tz extends TimeZone<Tz>>.fromUtcDateTimeAndOffset(
  /// The UTC [CDateTime].
  final CDateTime utcDateTime,

  /// The associated offset from UTC.
  final Offset<Tz> offset,
) implements ChronoFormattable<ZonedDateTimeFormatItem> {
  /// Returns a view to the naive local datetime.
  CDateTime get localDateTime => utcDateTime.addOffset(offset.fix());

  /// The associated [TimeZone].
  Tz get timeZone => offset.timeZone;

  /// The date corresponding to the given duration since the [unixEpoch].
  static ZonedDateTime<Utc> fromDurationSinceUnixEpoch(
    TimeDelta sinceUnixEpoch,
  ) => CDateTime.fromDurationSinceUnixEpoch(sinceUnixEpoch).andUtc();

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

  /// Turn this [ZonedDateTime] into a `ZonedDateTime<Utc>`, dropping the offset
  /// and associated timezone information.
  @useResult
  ZonedDateTime<Utc> toUtc() =>
      ZonedDateTime.fromUtcDateTimeAndOffset(utcDateTime, const Utc());

  /// Adds [duration] to this.
  ///
  /// The months and days of [duration] are added to the local date and time
  /// (so adding one day keeps the wall-clock time across DST transitions),
  /// whereas the time part is added on the UTC timeline.
  ///
  /// If the resulting local time is ambiguous (a fold), the current offset is
  /// kept if it is one of the candidates, otherwise the earlier one is used. If
  /// it doesn't exist (a gap), the result is shifted forward by the length of
  /// the gap.
  ZonedDateTime<Tz> operator +(ChronoDelta duration) {
    final delta = duration.asDateTimeDelta;
    final withCalendar = delta.months.inMonths == 0 && delta.days.inDays == 0
        ? this
        : _addCalendarDelta(delta.months, delta.days);
    if (delta.time.isZero) return withCalendar;

    return timeZone.fromUtcDateTime(withCalendar.utcDateTime + delta.time);
  }

  ZonedDateTime<Tz> operator -(ChronoDelta duration) => this + (-duration);

  /// Like [+], but reports a gap or fold instead of resolving it.
  ///
  /// The months and days of [duration] are added to the local date and time,
  /// and the result of mapping it back into the time zone is returned as is
  /// (so [MappedLocalTime_None] for a gap and [MappedLocalTime_Ambiguous] for a
  /// fold). The time part is then added on the UTC timeline.
  @useResult
  MappedLocalTime<ZonedDateTime<Tz>> checkedAdd(ChronoDelta duration) {
    final delta = duration.asDateTimeDelta;
    final withCalendar = delta.months.inMonths == 0 && delta.days.inDays == 0
        ? MappedLocalTime_Single(this)
        : timeZone.fromLocalDateTime(
            localDateTime +
                DateTimeDelta(months: delta.months, days: delta.days),
          );
    if (delta.time.isZero) return withCalendar;

    return withCalendar.map(
      (it) => timeZone.fromUtcDateTime(it.utcDateTime + delta.time),
    );
  }

  ZonedDateTime<Tz> _addCalendarDelta(Months months, Days days) {
    final local = localDateTime + DateTimeDelta(months: months, days: days);
    return switch (timeZone.offsetFromLocalDateTime(local)) {
      MappedLocalTime_Single(:final value) => _atOffset(local, value),
      MappedLocalTime_Ambiguous(:final earliest, :final latest) => _atOffset(
        local,
        latest == offset ? latest : earliest,
      ),
      MappedLocalTime_None() => _afterGap(local),
    };
  }

  ZonedDateTime<Tz> _atOffset(CDateTime local, Offset<Tz> offset) =>
      ZonedDateTime.fromUtcDateTimeAndOffset(
        local.subOffset(offset.fix()),
        offset,
      );

  /// Interprets the nonexistent [local] time with the offset from before the
  /// gap, which lands right after the gap.
  ZonedDateTime<Tz> _afterGap(CDateTime local) {
    // Transitions are far apart, so the offset a day before [local] is the one
    // in effect before the gap.
    final before = timeZone.offsetFromUtcDateTime(local - TimeDelta(hours: 24));
    return timeZone.fromUtcDateTime(local.subOffset(before.fix()));
  }

  /// Like [-], but reports a gap or fold instead of resolving it.
  ///
  /// See [checkedAdd] for details.
  @useResult
  MappedLocalTime<ZonedDateTime<Tz>> checkedSubtract(ChronoDelta duration) =>
      checkedAdd(-duration);

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

  /// Parses [string] as a strict RFC 3339 date and time, e.g.,
  /// “2015-01-20T17:35:20.001-08:00”.
  ///
  /// The date and time may be separated by `T`, `t`, or a space. The offset is
  /// `Z` or a signed `hh:mm`, and fractional seconds may have any number of
  /// digits (those beyond nanoseconds are ignored).
  ///
  /// Throws a [ChronoParseException] if [string] is not valid.
  static ZonedDateTime<FixedOffset> parseRfc3339(String string) =>
      ChronoParser.parseRfc3339(string).toZonedDateTime();

  /// Parses [string] as an RFC 2822 date and time, e.g.,
  /// “Tue, 20 Jan 2015 17:35:20 -0800”.
  ///
  /// The weekday and seconds are optional, whitespace is flexible, and
  /// trailing comments are ignored. The zone is a signed `hhmm` offset or a
  /// legacy name like `GMT` or `EST`. See [ChronoParser.parseRfc2822] for the
  /// full grammar.
  ///
  /// Throws a [ChronoParseException] if [string] is not valid.
  static ZonedDateTime<FixedOffset> parseRfc2822(String string) =>
      ChronoParser.parseRfc2822(string).toZonedDateTime();

  /// Represents a [ZonedDateTime] as an ISO 8601 date and time, followed by a
  /// space and the name of the [offset], e.g., “2023-04-23T18:24:20 EDT”.
  static const defaultFormat = <ZonedDateTimeFormatItem>[
    ...CDateTime.isoFormat,
    .literal(' '),
    .timezoneName(),
  ];

  /// Returns the items to format a [ZonedDateTime] as RFC 3339 and ISO 8601,
  /// e.g., “2023-04-23T18:24:20.123+09:30”.
  ///
  /// [secondsFormat] controls the number of subsecond digits, and [useZ]
  /// whether a zero offset is written as `Z` instead of `+00:00`.
  ///
  /// With the default options, this is Rust's `to_rfc3339()`.
  @useResult
  static List<ZonedDateTimeFormatItem> rfc3339Format({
    ChronoSecondsFormat secondsFormat = .variable,
    bool useZ = false,
  }) {
    final subsecondAccuracy = switch (secondsFormat) {
      .seconds => null,
      .millis => ChronoSubsecondAccuracy.millis,
      .micros => ChronoSubsecondAccuracy.micros,
      .nanos => ChronoSubsecondAccuracy.nanos,
      .variable => ChronoSubsecondAccuracy.variable,
    };
    return [
      ...Date.isoFormat,
      const .literal('T'),
      const .hour(),
      const .literal(':'),
      const .minute(),
      const .literal(':'),
      const .second(),
      if (subsecondAccuracy != null) .subsecond(subsecondAccuracy),
      .timezoneOffset(allowZulu: useZ),
    ];
  }

  @override
  String toString([List<ZonedDateTimeFormatItem> items = defaultFormat]) =>
      ChronoFormatter.format(
        items,
        date: localDateTime.date,
        time: localDateTime.time,
        offset: (name: offset.toString(), offset: offset.fix()),
      );

  // TODO(JonasWanke): use new [ChronoParser]
}
