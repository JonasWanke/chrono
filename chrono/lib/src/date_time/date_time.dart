import 'dart:core' as core;
import 'dart:core';

import 'package:cldr/cldr.dart' hide Days;
import 'package:clock/clock.dart' as cl;
import 'package:clock/clock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:oxidized/oxidized.dart';

import '../date/date.dart';
import '../date/duration.dart';
import '../date/month/month.dart';
import '../date/year.dart';
import '../formatting.dart';
import '../json.dart';
import '../parser.dart';
import '../rounding.dart';
import '../time/duration.dart';
import '../time/time.dart';
import '../unix_epoch_timestamp.dart';
import '../utils.dart';
import 'duration.dart';

part 'date_time.freezed.dart';

/// A date and time in the ISO 8601 calendar represented using [Date] and
/// [Time], e.g., April 23, 2023, at 18:24:20.
///
/// Leap years are taken into account. However, since this class doesn't care
/// about timezones, each day is exactly 24 hours long.
///
/// See also:
///
/// - [Date], which represents the date part.
/// - [Time], which represents the time part.
@immutable
final class DateTime
    with ComparisonOperatorsFromComparable<DateTime>
    implements Comparable<DateTime> {
  const DateTime(this.date, this.time);

  /// The UNIX epoch: 1970-01-01 at 00:00.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static final unixEpoch = Date.unixEpoch.at(Time.midnight);

  /// The date corresponding to the given duration since the [unixEpoch].
  factory DateTime.fromDurationSinceUnixEpoch(TimeDuration sinceUnixEpoch) {
    final (days, time) = sinceUnixEpoch.toDaysAndTime();
    final date = Date.fromDaysSinceUnixEpoch(days);
    return DateTime(date, time);
  }

  /// Creates a Chrono [DateTime] from a Dart Core [core.DateTime].
  ///
  /// This uses the [core.DateTime.year], [core.DateTime.month],
  /// [core.DateTime.day], [core.DateTime.hour], etc. getters and ignores
  /// whether that [core.ÐateTime] is in UTC or the local timezone.
  DateTime.fromCore(core.DateTime dateTime)
      : date = Date.from(
          Year(dateTime.year),
          Month.fromNumber(dateTime.month).unwrap(),
          dateTime.day,
        ).unwrap(),
        time = Time.from(
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          FractionalSeconds.millisecond * dateTime.millisecond +
              FractionalSeconds.microsecond * dateTime.microsecond,
        ).unwrap();
  DateTime.nowInLocalZone({Clock? clock})
      : this.fromCore((clock ?? cl.clock).now().toLocal());
  DateTime.nowInUtc({Clock? clock})
      : this.fromCore((clock ?? cl.clock).now().toUtc());

  final Date date;
  final Time time;

  /// The duration since the [unixEpoch].
  FractionalSeconds get durationSinceUnixEpoch {
    return time.fractionalSecondsSinceMidnight +
        date.daysSinceUnixEpoch.asNormalHours;
  }

  Instant get inLocalZone => Instant.fromCore(asCoreDateTimeInLocalZone);
  Instant get inUtc =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch);

  core.DateTime get asCoreDateTimeInLocalZone => _getDartDateTime(isUtc: false);
  core.DateTime get asCoreDateTimeInUtc => _getDartDateTime(isUtc: true);
  core.DateTime _getDartDateTime({required bool isUtc}) {
    return (isUtc ? core.DateTime.utc : core.DateTime.new)(
      date.year.number,
      date.month.number,
      date.day,
      time.hour,
      time.minute,
      time.second,
      0,
      time.fraction.roundToMicroseconds().inMicroseconds,
    );
  }

  DateTime operator +(Duration duration) {
    final compoundDuration = duration.asCompoundDuration;
    var newDate = date + compoundDuration.months + compoundDuration.days;

    final (days, newTime) =
        (time.fractionalSecondsSinceMidnight + compoundDuration.seconds)
            .toDaysAndTime();
    newDate += days;
    return DateTime(newDate, newTime);
  }

  DateTime operator -(Duration duration) => this + (-duration);

  /// Returns `this - other` as days and fractional seconds.
  ///
  /// The returned [CompoundDuration]'s days and seconds are both `>= 0` or both
  /// `<= 0`. The months will always be zero.
  CompoundDuration difference(DateTime other) {
    if (this < other) return -other.difference(this);

    var days = date.differenceInDays(other.date);
    FractionalSeconds seconds;
    if (time < other.time) {
      days -= const Days(1);
      seconds = time.difference(other.time) + const Days(1).asNormalHours;
    } else {
      seconds = time.difference(other.time);
    }

    return CompoundDuration(days: days, seconds: seconds);
  }

  /// Returns `this - other` as fractional seconds.
  ///
  /// The returned [CompoundDuration]'s days and seconds are both `>= 0` or both
  /// `<= 0`. The months will always be zero.
  FractionalSeconds timeDifference(DateTime other) {
    final difference = this.difference(other);
    assert(difference.months.isZero);
    return difference.seconds + difference.days.asNormalHours;
  }

  DateTime roundTimeToMultipleOf(
    TimeDuration duration, {
    Rounding rounding = Rounding.nearestAwayFromZero,
  }) =>
      date.at(time.roundToMultipleOf(duration, rounding: rounding));

  DateTime copyWith({Date? date, Time? time}) =>
      DateTime(date ?? this.date, time ?? this.time);

  @override
  int compareTo(DateTime other) {
    final result = date.compareTo(other.date);
    if (result != 0) return result;

    return time.compareTo(other.time);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DateTime && date == other.date && time == other.time);
  }

  @override
  int get hashCode => Object.hash(date, time);

  @override
  String toString() => '${date}T$time';
}

extension on TimeDuration {
  (Days, Time) toDaysAndTime() {
    var (seconds, fraction) = asSecondsAndFraction;
    if (seconds.isZero && fraction.isNegative) {
      seconds = -const Seconds(1);
      fraction += FractionalSeconds.second;
    }

    final days = seconds.roundToNormalDays(rounding: Rounding.down);
    final secondsWithinDay = seconds - days.asNormalSeconds;
    final time =
        Time.fromTimeSinceMidnight(fraction + secondsWithinDay).unwrap();
    return (days, time);
  }
}

/// Encodes a [DateTime] as an ISO 8601 string, e.g., “2023-04-23T18:24:20.12”.
class DateTimeAsIsoStringJsonConverter
    extends JsonConverterWithParserResult<DateTime, String> {
  const DateTimeAsIsoStringJsonConverter();

  @override
  Result<DateTime, FormatException> resultFromJson(String json) =>
      Parser.parseDateTime(json);
  @override
  String toJson(DateTime object) => object.toString();
}

class LocalizedDateTimeFormatter extends LocalizedFormatter<DateTime> {
  const LocalizedDateTimeFormatter(super.localeData, this.style);

  final DateTimeStyle style;

  @override
  String format(DateTime value) {
    return style.when(
      (length, useAtTimeVariant) => _formatLengths(
        value,
        dateLength: length,
        timeLength: length,
        useAtTimeVariant: useAtTimeVariant,
      ),
      lengths: (dateLength, timeLength, useAtTimeVariant) => _formatLengths(
        value,
        dateLength: dateLength,
        timeLength: timeLength,
        useAtTimeVariant: useAtTimeVariant,
      ),
    );
  }

  String _formatLengths(
    DateTime value, {
    required DateOrTimeFormatLength dateLength,
    required DateOrTimeFormatLength timeLength,
    required bool useAtTimeVariant,
  }) {
    final lengthFormats = localeData
        .dates.calendars.gregorian.dateTimeFormats.formats[dateLength];
    final format = useAtTimeVariant
        ? (lengthFormats.atTime ?? lengthFormats.standard)
        : lengthFormats.standard;

    final dateFormatter =
        LocalizedDateFormatter(localeData, DateStyle(dateLength));
    final timeFormatter =
        LocalizedTimeFormatter(localeData, TimeStyle(timeLength));

    return format.pattern
        .map(
          (it) => it.when(
            literal: (value) => value,
            date: () => dateFormatter.format(value.date),
            time: () => timeFormatter.format(value.time),
            field: (field) => field.when(
              dateField: (field) =>
                  dateFormatter.formatField(value.date, field),
              timeField: (field) =>
                  timeFormatter.formatField(value.time, field),
            ),
          ),
        )
        .join();
  }
}

@freezed
class DateTimeStyle with _$DateTimeStyle {
  // TODO(JonasWanke): customizable component formats

  const factory DateTimeStyle(
    DateOrTimeFormatLength length, {
    @Default(false) bool useAtTimeVariant,
  }) = _DateTimeStyleLength;

  const factory DateTimeStyle.lengths({
    required DateOrTimeFormatLength dateLength,
    required DateOrTimeFormatLength timeLength,
    @Default(false) bool useAtTimeVariant,
  }) = _DateTimeStyleLengths;

  const DateTimeStyle._();
}
