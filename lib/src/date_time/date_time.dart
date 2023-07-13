import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../date/date.dart';
import '../date/duration.dart';
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
      : date = Date.fromCore(dateTime),
        time = Time.fromCore(dateTime);
  DateTime.nowInLocalZone({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now().toLocal());
  DateTime.nowInUtc({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now().toUtc());

  factory DateTime.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<DateTime, FormatException> parse(String value) =>
      Parser.parseDateTime(value);

  final Date date;
  final Time time;

  Instant get inLocalZone => Instant.fromCore(coreDateTimeInLocalZone);
  Instant get inUtc => Instant.fromCore(coreDateTimeInUtc);

  core.DateTime get coreDateTimeInLocalZone => _getDartDateTime(isUtc: false);
  core.DateTime get coreDateTimeInUtc => _getDartDateTime(isUtc: true);
  core.DateTime _getDartDateTime({required bool isUtc}) {
    return (isUtc ? core.DateTime.utc : core.DateTime.new)(
      date.year.value,
      date.month.number,
      date.day,
      time.hour,
      time.minute,
      time.second,
      0,
      time.fraction.inMicrosecondsRounded,
    );
  }

  DateTime operator +(Duration duration) {
    final compoundDuration = duration.asCompoundDuration;
    var newDate = date + compoundDuration.months + compoundDuration.days;

    final rawNewTimeSinceMidnight =
        time.fractionalSecondsSinceMidnight + compoundDuration.seconds;
    final (rawNewSecondsSinceMidnight, newFractionSinceMidnight) =
        rawNewTimeSinceMidnight.inSecondsAndFraction;
    newDate += Days(rawNewSecondsSinceMidnight.value ~/ Seconds.perDay.value);
    final newTime = Time.fromTimeSinceMidnightUnchecked(
      newFractionSinceMidnight +
          rawNewSecondsSinceMidnight.remainder(Seconds.perDay.value),
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
