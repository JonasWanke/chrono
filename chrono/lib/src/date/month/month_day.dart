import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../../codec.dart';
import '../../parser.dart';
import '../../utils.dart';
import '../date.dart';
import 'month.dart';

/// The combination of a [Month] and a day of the month, e.g., April 23.
///
/// Since [MonthDay] does not include a year, February 29 is considered valid.
///
/// See also:
///
/// - [Date], which also includes a year.
@immutable
final class MonthDay
    with ComparisonOperatorsFromComparable<MonthDay>
    implements Comparable<MonthDay> {
  static Result<MonthDay, String> from(Month month, int day) {
    if (day < 1 || day > month.maxLength.inDays) {
      return Err('Invalid day for $month: $day');
    }
    return Ok(MonthDay._(month, day));
  }

  static Result<MonthDay, String> fromRaw(int month, int day) =>
      Month.fromNumber(month).andThen((month) => from(month, day));

  const MonthDay._(this.month, this.day);

  factory MonthDay.todayInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).monthDay;
  factory MonthDay.todayInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).monthDay;

  final Month month;

  /// The one-based day of the month.
  final int day;

  bool isTodayInLocalZone({Clock? clock}) =>
      this == MonthDay.todayInLocalZone(clock: clock);
  bool isTodayInUtc({Clock? clock}) =>
      this == MonthDay.todayInUtc(clock: clock);

  Result<MonthDay, String> copyWith({Month? month, int? day}) =>
      MonthDay.from(month ?? this.month, day ?? this.day);

  @override
  int compareTo(MonthDay other) {
    final result = month.compareTo(other.month);
    if (result != 0) return result;

    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is MonthDay && month == other.month && day == other.day);
  }

  @override
  int get hashCode => Object.hash(month, day);

  @override
  String toString() {
    final month = this.month.number.toString().padLeft(2, '0');
    final day = this.day.toString().padLeft(2, '0');
    return '--$month-$day';
  }
}

/// Encodes a [MonthDay] as an ISO 8601 string, e.g., --04-23”.
class MonthDayAsIsoStringCodec extends CodecWithParserResult<MonthDay, String> {
  const MonthDayAsIsoStringCodec();

  @override
  String encode(MonthDay input) => input.toString();
  @override
  Result<MonthDay, FormatException> decodeAsResult(String encoded) =>
      Parser.parseMonthDay(encoded);
}
