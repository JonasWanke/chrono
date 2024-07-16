import 'package:cldr/cldr.dart' as cldr;
import 'package:clock/clock.dart';
import 'package:oxidized/oxidized.dart';

import '../formatting.dart';
import '../json.dart';
import '../utils.dart';
import 'date.dart';
import 'duration.dart';

/// A weekday in the ISO 8601 calendar, e.g., Sunday.
///
/// In this calendar, the week starts on Monday and ends on Sunday.
enum Weekday
    with ComparisonOperatorsFromComparable<Weekday>
    implements Comparable<Weekday> {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday;

  /// Returns the weekday with the given [index].
  ///
  /// The index must be in the range 0 for Monday, …, 6 for Sunday. For any
  /// other number, an error is returned.
  static Result<Weekday, String> fromIndex(int index) {
    if (index < minIndex || index > maxIndex) {
      return Err('Invalid weekday index: $index');
    }
    return Ok(values[index - Weekday.minIndex]);
  }

  /// Returns the weekday with the given [number].
  ///
  /// The number must be in the range 1 for Monday, …, 7 for Sunday. For any
  /// other number, an error is returned.
  static Result<Weekday, String> fromNumber(int number) {
    if (number < minNumber || number > maxNumber) {
      return Err('Invalid weekday number: $number');
    }
    return Ok(values[number - Weekday.minNumber]);
  }

  factory Weekday.currentInLocalZone({Clock? clock}) =>
      Date.todayInLocalZone(clock: clock).weekday;
  factory Weekday.currentInUtc({Clock? clock}) =>
      Date.todayInUtc(clock: clock).weekday;

  static const minIndex = 0; // Weekday.monday.index
  static const maxIndex = 6; // Weekday.sunday.index
  static const minNumber = 1; // Weekday.monday.number
  static const maxNumber = 7; // Weekday.sunday.number

  /// The number of this weekday (1 for Monday, …, 7 for Sunday).
  int get isoNumber => index + 1;

  /// The number of this weekday (from 1 to 7) with [firstDayOfWeek] equal to 1.
  int number({required Weekday firstDayOfWeek}) =>
      (Days.perWeek + index - firstDayOfWeek.index) % Days.perWeek + 1;

  // TODO: index with `firstDayOfWeek`

  bool isCurrentInLocalZone({Clock? clock}) =>
      this == Weekday.currentInLocalZone(clock: clock);
  bool isCurrentInUtc({Clock? clock}) =>
      this == Weekday.currentInUtc(clock: clock);

  Weekday operator +(FixedDaysDuration duration) =>
      values[(index + duration.asDays.inDays) % values.length];
  Weekday operator -(FixedDaysDuration duration) => this + (-duration);

  /// The weekday after this one, wrapping around after Sunday.
  Weekday get next => this + const Days(1);

  /// The weekday before this one, wrapping around before Monday.
  Weekday get previous => this - const Days(1);

  /// The number of days from this weekday to the next [other] weekday.
  ///
  /// The result is always in the range `Days(0)` to `Days(6)`.
  Days untilNextOrSame(Weekday other) =>
      Days((other.index - index) % values.length);

  /// The number of days from this weekday to the previous [other] weekday.
  ///
  /// The result is always in the range `Days(0)` to `Days(-6)`.
  Days untilPreviousOrSame(Weekday other) =>
      Days(-((index - other.index) % values.length));

  @override
  int compareTo(Weekday other) => index.compareTo(other.index);

  @override
  String toString() {
    return switch (this) {
      Weekday.monday => 'Monday',
      Weekday.tuesday => 'Tuesday',
      Weekday.wednesday => 'Wednesday',
      Weekday.thursday => 'Thursday',
      Weekday.friday => 'Friday',
      Weekday.saturday => 'Saturday',
      Weekday.sunday => 'Sunday',
    };
  }
}

/// Encodes a [Weekday] as an ISO 8601 weekday number: 1 for Monday, …, 7 for
/// Sunday.
class WeekdayAsIntJsonConverter
    extends JsonConverterWithStringResult<Weekday, int> {
  const WeekdayAsIntJsonConverter();

  @override
  Result<Weekday, String> resultFromJson(int json) => Weekday.fromNumber(json);

  @override
  int toJson(Weekday object) => object.isoNumber;
}

class LocalizedWeekdayFormatter extends LocalizedFormatter<Weekday> {
  const LocalizedWeekdayFormatter(super.localeData, this.style);

  final cldr.WeekdayStyle style;

  @override
  String format(Weekday value) {
    final days = localeData.dates.calendars.gregorian.days;
    String selectFrom(cldr.Days days) {
      return switch (value) {
        Weekday.monday => days.monday,
        Weekday.tuesday => days.tuesday,
        Weekday.wednesday => days.wednesday,
        Weekday.thursday => days.thursday,
        Weekday.friday => days.friday,
        Weekday.saturday => days.saturday,
        Weekday.sunday => days.sunday,
      };
    }

    return style.when(
      format: (width) => switch (width) {
        cldr.DayFieldWidth.narrow => selectFrom(days.format.narrow),
        cldr.DayFieldWidth.short => selectFrom(days.format.short),
        cldr.DayFieldWidth.abbreviated => selectFrom(days.format.abbreviated),
        cldr.DayFieldWidth.wide => selectFrom(days.format.wide),
      },
      // TODO(JonasWanke): use localized numbers
      formatNumeric: (isPadded) => isPadded
          ? value.isoNumber.toString().padLeft(2, '0')
          : value.isoNumber.toString(),
      standalone: (width) => switch (width) {
        cldr.DayFieldWidth.narrow => selectFrom(days.standalone.narrow),
        cldr.DayFieldWidth.short => selectFrom(days.standalone.short),
        cldr.DayFieldWidth.abbreviated =>
          selectFrom(days.standalone.abbreviated),
        cldr.DayFieldWidth.wide => selectFrom(days.standalone.wide),
      },
      // TODO(JonasWanke): use localized numbers
      standaloneNumeric: () => value.isoNumber.toString(),
    );
  }
}
