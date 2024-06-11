import 'dart:core' as core;
import 'dart:core';

import 'package:cldr/cldr.dart' as cldr;
import 'package:clock/clock.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:oxidized/oxidized.dart';

import '../../formatting.dart';
import '../../json.dart';
import '../../utils.dart';
import '../date.dart';
import '../duration.dart';
import 'month_day.dart';

part 'month.freezed.dart';

/// A month in the ISO 8601 calendar, e.g., April.
enum Month
    with ComparisonOperatorsFromComparable<Month>
    implements Comparable<Month> {
  january,
  february,
  march,
  april,
  may,
  june,
  july,
  august,
  september,
  october,
  november,
  december;

  /// Returns the month with the given [index].
  ///
  /// The index must be in the range 0 for January, …, 11 for December. For any
  /// other number, an error is returned.
  static Result<Month, String> fromIndex(int index) {
    if (index < minIndex || index > maxIndex) {
      return Err('Invalid month index: $index');
    }
    return Ok(values[index - minIndex]);
  }

  /// Returns the month with the given [number].
  ///
  /// The number must be in the range 1 for January, …, 12 for December. For any
  /// other number, an error is returned.
  static Result<Month, String> fromNumber(int number) {
    if (number < minNumber || number > maxNumber) {
      return Err('Invalid month number: $number');
    }
    return Ok(values[number - minNumber]);
  }

  static Month currentInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).month;
  static Month currentInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).month;

  static const minIndex = 1; // Month.january.index
  static const maxIndex = 12; // Month.december.index
  static const minNumber = 1; // Month.january.number
  static const maxNumber = 12; // Month.december.number

  /// The number of this month (1 for January, …, 12 for December).
  int get number => index + 1;

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == Month.currentInLocalZone(clock: clock);
  bool isCurrentInUtc({Clock? clock}) =>
      this == Month.currentInUtc(clock: clock);

  /// The number of days in this month of a common (non-leap) year.
  ///
  /// The result is always in the range [28, 31].
  Days get lengthInCommonYear {
    // https://howardhinnant.github.io/date_algorithms.html#last_day_of_month_common_year
    const days = [
      //
      Days(31), Days(28), Days(31), Days(30), Days(31), Days(30),
      Days(31), Days(31), Days(30), Days(31), Days(30), Days(31),
    ];
    return days[index];
  }

  /// The number of days in this month of a leap year.
  ///
  /// The result is always in the range [29, 31].
  Days get lengthInLeapYear {
    // https://howardhinnant.github.io/date_algorithms.html#last_day_of_month_leap_year
    const days = [
      //
      Days(31), Days(29), Days(31), Days(30), Days(31), Days(30),
      Days(31), Days(31), Days(30), Days(31), Days(30), Days(31),
    ];
    return days[index];
  }

  /// The minimum number of days in this month.
  Days get minLength => lengthInCommonYear;

  /// The maximum number of days in this month.
  Days get maxLength => lengthInLeapYear;

  MonthDay get firstDay => MonthDay.from(this, 1).unwrap();
  MonthDay get lastDayInCommonYear =>
      MonthDay.from(this, lengthInCommonYear.inDays).unwrap();
  MonthDay get lastDayInLeapYear =>
      MonthDay.from(this, lengthInLeapYear.inDays).unwrap();
  MonthDay get minLastDay => lastDayInCommonYear;
  MonthDay get maxLastDay => lastDayInLeapYear;

  Month operator +(MonthsDuration duration) =>
      values[(index + duration.asMonths.inMonths) % values.length];
  Month operator -(MonthsDuration duration) => this + (-duration);

  /// The month after this one, wrapping around after January.
  Month get next => this + const Months(1);

  /// The month before this one, wrapping around before January.
  Month get previous => this - const Months(1);

  /// The number of months from this month to the next [other] month.
  ///
  /// The result is always in the range `Months(0)` to `Months(11)`.
  Months untilNextOrSame(Month other) =>
      Months((other.index - index) % values.length);

  /// The number of months from this month to the previous [other] month.
  ///
  /// The result is always in the range `Months(0)` to `Months(-11)`.
  Months untilPreviousOrSame(Month other) =>
      Months(-((index - other.index) % values.length));

  @override
  int compareTo(Month other) => index.compareTo(other.index);

  @override
  String toString() {
    return switch (this) {
      Month.january => 'January',
      Month.february => 'February',
      Month.march => 'March',
      Month.april => 'April',
      Month.may => 'May',
      Month.june => 'June',
      Month.july => 'July',
      Month.august => 'August',
      Month.september => 'September',
      Month.october => 'October',
      Month.november => 'November',
      Month.december => 'December',
    };
  }
}

/// Encodes a [Month] as an int: 1 for January, …, 12 for December.
class MonthAsIntJsonConverter
    extends JsonConverterWithStringResult<Month, int> {
  const MonthAsIntJsonConverter();

  @override
  Result<Month, String> resultFromJson(int json) => Month.fromNumber(json);

  @override
  int toJson(Month object) => object.number;
}

class LocalizedMonthFormatter extends LocalizedFormatter<Month> {
  const LocalizedMonthFormatter(super.localeData, this.style);

  final MonthStyle style;

  @override
  String format(Month value) {
    final months = localeData.dates.calendars.gregorian.months;
    return style.when(
      // TODO(JonasWanke): use localized numbers
      numeric: (isPadded) => isPadded
          ? value.number.toString().padLeft(2, '0')
          : value.number.toString(),
      format: (width) => switch (width) {
        FieldWidth.narrow => months.format.narrow[value.number]!.unwrap(),
        FieldWidth.abbreviated =>
          months.format.abbreviated[value.number]!.unwrap(),
        FieldWidth.wide => months.format.wide[value.number]!.unwrap(),
      },
      standalone: (width) => switch (width) {
        FieldWidth.narrow => months.standalone.narrow[value.number]!.unwrap(),
        FieldWidth.abbreviated =>
          months.standalone.abbreviated[value.number]!.unwrap(),
        FieldWidth.wide => months.standalone.wide[value.number]!.unwrap(),
      },
    );
  }
}

extension<T extends Object> on cldr.Value<T> {
  T unwrap() => whenOrNull((it) => it)!;
}

@freezed
class MonthStyle with _$MonthStyle {
  /// The month as a number, e.g., 1 for January.
  ///
  /// If [isPadded] is `true`, the number is padded to two digits with leading
  /// zeros.
  const factory MonthStyle.numeric({required bool isPadded}) =
      _MonthStyleNumeric;

  /// Format so that it can be used in a formatted date
  const factory MonthStyle.format({required FieldWidth width}) =
      _MonthStyleFormat;

  /// The so that it can be used in a stand-alone context, e.g., in a calendar
  /// header.
  const factory MonthStyle.standalone({required FieldWidth width}) =
      _MonthStyleStandAlone;

  const MonthStyle._();
}
