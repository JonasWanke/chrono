import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:clock/clock.dart' as cl;
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../date/date.dart';
import '../date/duration.dart';
import '../date/month/month.dart';
import '../date/year.dart';
import '../parser.dart';
import '../time/duration.dart';
import '../time/time.dart';
import '../utils.dart';
import 'duration.dart';
import 'instant.dart';

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
    final (seconds, fraction) = sinceUnixEpoch.asSecondsAndFraction;

    final days = Days(seconds.inSeconds ~/ Seconds.perNormalDay);
    final date = Date.fromDaysSinceUnixEpoch(days);

    final secondsWithinDay = seconds.remainder(Seconds.perNormalDay);
    final time =
        Time.fromTimeSinceMidnight(fraction + secondsWithinDay).unwrap();

    return DateTime(date, time);
  }

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

  factory DateTime.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<DateTime, FormatException> parse(String value) =>
      Parser.parseDateTime(value);

  final Date date;
  final Time time;

  /// The duration since the [unixEpoch].
  FractionalSeconds get durationSinceUnixEpoch {
    return time.fractionalSecondsSinceMidnight +
        date.daysSinceUnixEpoch.asNormalHours;
  }

  Instant get inLocalZone => Instant.fromCore(asCoreDateTimeInLocalZone);
  Instant get inUtc => Instant.fromCore(asCoreDateTimeInUtc);

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

    final rawNewTimeSinceMidnight =
        time.fractionalSecondsSinceMidnight + compoundDuration.seconds;
    final (rawNewSecondsSinceMidnight, newFractionSinceMidnight) =
        rawNewTimeSinceMidnight.asSecondsAndFraction;
    newDate +=
        Days(rawNewSecondsSinceMidnight.inSeconds ~/ Seconds.perNormalDay);
    final newTime = Time.fromTimeSinceMidnight(
      newFractionSinceMidnight +
          rawNewSecondsSinceMidnight.remainder(Seconds.perNormalDay),
    ).unwrap();
    return DateTime(newDate, newTime);
  }

  DateTime operator -(Duration duration) => this + (-duration);

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

  String toJson() => toString();
}
