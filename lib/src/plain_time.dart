import 'package:clock/clock.dart';
import 'package:fixed/fixed.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'parser.dart';
import 'utils.dart';

@immutable
final class PlainTime
    with ComparisonOperatorsFromComparable<PlainTime>
    implements Comparable<PlainTime> {
  PlainTime(this.hour, [this.minute = 0, this.second = 0, Fixed? fraction])
      : fraction = fraction ?? Fixed.zero;
  // TODO: validation

  PlainTime.fromDateTime(DateTime dateTime)
      : hour = dateTime.hour,
        minute = dateTime.minute,
        second = dateTime.second,
        fraction = Fixed.fromInt(
          dateTime.millisecond * Duration.microsecondsPerMillisecond +
              dateTime.microsecond,
          scale: 6,
        );
  PlainTime.nowInLocalZone({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toLocal());
  PlainTime.nowInUtc({Clock? clockOverride})
      : this.fromDateTime((clockOverride ?? clock).now().toUtc());

  factory PlainTime.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<PlainTime, FormatException> parse(String value) =>
      Parser.parseTime(value);

  final int hour;
  final int minute;
  final int second;
  final Fixed fraction;

  // TODO: week and day of week

  PlainTime copyWith({
    int? hour,
    int? minute,
    int? second,
    Fixed? fraction,
  }) {
    // TODO: throwing/clamping/wrapping variants?
    return PlainTime(
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      fraction ?? this.fraction,
    );
  }

  @override
  int compareTo(PlainTime other) {
    if (hour != other.hour) return hour.compareTo(other.hour);
    if (minute != other.minute) return minute.compareTo(other.minute);
    if (second != other.second) return second.compareTo(other.second);
    return fraction.compareTo(other.fraction);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PlainTime &&
            hour == other.hour &&
            minute == other.minute &&
            second == other.second &&
            fraction == other.fraction);
  }

  @override
  int get hashCode => Object.hash(hour, minute, second, fraction);

  @override
  String toString() {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    final second = this.second.toString().padLeft(2, '0');
    final fraction = this.fraction == Fixed.zero
        ? ''
        : this.fraction.toString().substring(1);
    return '$hour:$minute:$second$fraction';
  }

  String toJson() => toString();
}
