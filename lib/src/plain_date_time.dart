import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'instant.dart';
import 'parser.dart';
import 'plain_date.dart';
import 'plain_time.dart';
import 'utils.dart';

@immutable
final class PlainDateTime
    with ComparisonOperatorsFromComparable<PlainDateTime>
    implements Comparable<PlainDateTime> {
  const PlainDateTime(this.date, this.time);
  PlainDateTime.fromDateTime(DateTime dateTime)
      : date = PlainDate.fromDateTime(dateTime),
        time = PlainTime.fromDateTime(dateTime);

  factory PlainDateTime.fromJson(String json) =>
      unwrapParserResult(parse(json));
  static Result<PlainDateTime, FormatException> parse(String value) =>
      Parser.parseDateTime(value);

  final PlainDate date;
  final PlainTime time;

  Instant get inLocalZone => Instant.fromDateTime(dateTimeInLocalZone);
  Instant get inUtc => Instant.fromDateTime(dateTimeInUtc);

  DateTime get dateTimeInLocalZone {
    return DateTime(
      date.year.value,
      date.month.number,
      date.day,
      time.hour,
      time.minute,
      time.second,
      // time.millisecond, // TODO
      // time.microsecond,
    );
  }

  DateTime get dateTimeInUtc {
    return DateTime.utc(
      date.year.value,
      date.month.number,
      date.day,
      time.hour,
      time.minute,
      time.second,
      // time.millisecond, // TODO
      // time.microsecond,
    );
  }

  PlainDateTime copyWith({PlainDate? date, PlainTime? time}) =>
      PlainDateTime(date ?? this.date, time ?? this.time);

  @override
  int compareTo(PlainDateTime other) {
    final result = date.compareTo(other.date);
    if (result != 0) return result;

    return time.compareTo(other.time);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlainDateTime && date == other.date && time == other.time);
  }

  @override
  int get hashCode => Object.hash(date, time);

  @override
  String toString() => '${date}T$time';

  String toJson() => toString();
}
