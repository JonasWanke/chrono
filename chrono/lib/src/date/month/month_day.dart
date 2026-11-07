import 'package:clock/clock.dart';
import 'package:meta/meta.dart';

import '../../codec.dart';
import '../../parser.dart';
import '../../utils.dart';
import '../date.dart';
import '../year.dart';
import 'month.dart';

/// The combination of a [Month] and a day of the month, e.g., April 23.
///
/// Since [MonthDay] does not include a year, February 29 is considered valid.
///
/// See also:
///
/// - [Date], which also includes a year.
@immutable
final class const MonthDay._unchecked(
  final Month month,

  /// The one-based day of the month.
  final int day,
) with ComparisonOperatorsFromComparable<MonthDay>
    implements Comparable<MonthDay> {
  /// Creates a month and day from raw numbers, e.g., `MonthDay(4, 23)`.
  ///
  /// Throws a [RangeError] if [month] or [day] is out of range.
  new(int month, int day) : this.from(Month.fromNumber(month), day);

  /// Creates a month and day from typed components, e.g.,
  /// `MonthDay.from(Month.april, 23)`.
  ///
  /// Throws a [RangeError] if [day] is invalid for [month]. February 29 is
  /// valid.
  new from(Month month, int day)
    : this._unchecked(
        month,
        RangeError.checkValueInInterval(
          day,
          1,
          month.maxLength.inDays,
          'day',
          'Invalid day for $month.',
        ),
      );

  factory todayInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).monthDay;
  factory todayInUtc({Clock? clock}) => Date.todayInUtc(clock: clock).monthDay;

  bool isTodayInLocalZone({Clock? clock}) =>
      this == MonthDay.todayInLocalZone(clock: clock);
  bool isTodayInUtc({Clock? clock}) =>
      this == MonthDay.todayInUtc(clock: clock);

  /// The [Date] of this month and day in the given [year].
  ///
  /// Throws a [RangeError] for February 29 in a common year.
  Date inYear(Year year) => Date.from(year, month, day);

  /// Like [inYear], but returns `null` for February 29 in a common year.
  Date? inYearOrNull(Year year) => year.atMonth(month).atDayOrNull(day);

  MonthDay copyWith({Month? month, int? day}) =>
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
class const MonthDayAsIsoStringCodec()
    extends CodecAndJsonConverter<MonthDay, String> {
  @override
  String encode(MonthDay input) => input.toString();
  @override
  MonthDay decode(String encoded) => Parser.parseMonthDay(encoded);
}
