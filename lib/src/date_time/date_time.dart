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

  DateTime.fromCore(core.DateTime dateTime)
      : date = Date.fromUnchecked(
          Year(dateTime.year),
          Month.fromNumberUnchecked(dateTime.month),
          dateTime.day,
        ),
        time = Time.fromUnchecked(
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          FractionalSeconds.millisecond * dateTime.millisecond +
              FractionalSeconds.microsecond * dateTime.microsecond,
        );
  DateTime.nowInLocalZone({Clock? clock})
      : this.fromCore((clock ?? cl.clock).now().toLocal());
  DateTime.nowInUtc({Clock? clock})
      : this.fromCore((clock ?? cl.clock).now().toUtc());

  factory DateTime.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<DateTime, FormatException> parse(String value) =>
      Parser.parseDateTime(value);

  final Date date;
  final Time time;

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
      time.fraction.asMicrosecondsRounded,
    );
  }

  DateTime operator +(Duration duration) {
    final compoundDuration = duration.asCompoundDuration;
    var newDate = date + compoundDuration.months + compoundDuration.days;

    final rawNewTimeSinceMidnight =
        time.fractionalSecondsSinceMidnight + compoundDuration.seconds;
    final (rawNewSecondsSinceMidnight, newFractionSinceMidnight) =
        rawNewTimeSinceMidnight.asSecondsAndFraction;
    newDate += Days(rawNewSecondsSinceMidnight.value ~/ Seconds.perNormalDay);
    final newTime = Time.fromTimeSinceMidnightUnchecked(
      newFractionSinceMidnight +
          rawNewSecondsSinceMidnight.remainder(Seconds.perNormalDay),
    );
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
