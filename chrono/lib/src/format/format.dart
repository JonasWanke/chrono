import '../../chrono.dart';

// Shared

/// A single formatting item.
///
/// This is used for both formatting and parsing.
sealed class const ChronoFormatItem() {
  const factory literal(String text) = ChronoFormatItemLiteral;
  const factory space(String text) = ChronoFormatItemSpace;
  const factory year({YearFormat format, ChronoPadding padding}) =
      ChronoFormatYear;
  const factory isoYear({YearFormat format, ChronoPadding padding}) =
      ChronoFormatIsoYear;
  const factory quarter({ChronoPadding padding}) = ChronoFormatQuarter;
  const factory month({ChronoPadding padding}) = ChronoFormatMonth;
  const factory day({ChronoPadding padding}) = ChronoFormatDay;
  const factory weekFromSun({ChronoPadding padding}) = ChronoFormatWeekFromSun;
  const factory weekFromMon({ChronoPadding padding}) = ChronoFormatWeekFromMon;
  const factory isoWeek({ChronoPadding padding}) = ChronoFormatIsoWeek;
  const factory numDaysFromSun({ChronoPadding padding}) =
      ChronoFormatNumDaysFromSun;
  const factory weekday({ChronoPadding padding}) = ChronoFormatWeekday;
  const factory ordinal({ChronoPadding padding}) = ChronoFormatOrdinal;
  const factory hour({ChronoPadding padding}) = ChronoFormatHour;
  const factory hour12({ChronoPadding padding}) = ChronoFormatHour12;
  const factory minute({ChronoPadding padding}) = ChronoFormatMinute;
  const factory second({ChronoPadding padding}) = ChronoFormatSecond;
  const factory nanosecond({ChronoPadding padding}) = ChronoFormatNanosecond;
  const factory timestamp({ChronoPadding padding}) = ChronoFormatTimestamp;
  const factory monthName(ChronoFormatLength length) = ChronoFormatMonthName;
  const factory weekdayName(ChronoFormatLength length) =
      ChronoFormatWeekdayName;
  const factory amPm(ChronoCasing casing) = ChronoFormatAmPm;
  const factory subsecond(ChronoSubsecondAccuracy accuracy) =
      ChronoFormatSubsecond;
  const factory timezoneName() = ChronoFormatTimezoneName;
  const factory timezoneOffset({
    TimezoneOffsetPrecision precision,
    bool allowZulu,
    bool printColon,
  }) = ChronoFormatTimezoneOffset;
}

/// A literally printed and parsed text.
class const ChronoFormatItemLiteral(final String text)
    extends ChronoFormatItem
    implements DateFormatItem, TimeFormatItem;

/// Whitespace. Prints literally but reads zero or more whitespace.
class const ChronoFormatItemSpace(final String text)
    extends ChronoFormatItem
    implements DateFormatItem, TimeFormatItem;

/// Numeric items.
///
/// They have associated formatting width (FW) and parsing width (PW).
///
/// The **formatting width** is the minimal width to be formatted. If the number
/// is too short, and the padding is not [ChronoPadding.none], then it is
/// left-padded. If the number is too long or (in some cases) negative, it is
/// printed as is.
///
/// The **parsing width** is the maximal width to be scanned. The parser only
/// tries to consume from one to given number of digits (greedily). It also
/// trims the preceding whitespace if any. It cannot parse the negative number,
/// so some date and time cannot be formatted then parsed with the same
/// formatting items.
sealed class const ChronoFormatItemNumeric({
  final ChronoPadding padding = .zero,
}) extends ChronoFormatItem;

/// Padding characters for [ChronoFormatItemNumeric].
enum ChronoPadding {
  /// No padding.
  none,

  /// Pad using zeros (`0`).
  zero,

  /// Pad using spaces.
  space,
}

/// Which length to use when formatting/parsing month/weekday names.
enum ChronoFormatLength {
  /// Prints the three-letter-long name in title case, reads the same name in
  /// any case.
  short,

  /// Prints the full name, reads either the three-letter-long name or the
  /// full name in any case.
  full,
}

/// Fixed-format items.
///
/// They have their own rules of formatting and parsing.
///
/// Unless otherwise noted, they print in the specified case but parse
/// case-insensitively.
sealed class const ChronoFormatItemFixed() extends ChronoFormatItem;

/// Issues a formatting error. Used to signal an invalid format string.
// TODO(JonasWanke): Is this necessary?
class ChronoFormatItemError extends ChronoFormatItem;

abstract interface class ChronoFormattable<I extends ChronoFormatItem> {
  @override
  String toString([List<I> items]);
}

// ZonedDateTime

/// A [ChronoFormatItem] that is used for formatting [ZonedDateTime]s.
///
/// This includes all [CDateTimeFormatItem]s, applied to the local date and
/// time, plus items for the time zone.
sealed class ZonedDateTimeFormatItem extends ChronoFormatItem {
  const factory literal(String text) = ChronoFormatItemLiteral;
  const factory space(String text) = ChronoFormatItemSpace;
  const factory year({YearFormat format, ChronoPadding padding}) =
      ChronoFormatYear;
  const factory isoYear({YearFormat format, ChronoPadding padding}) =
      ChronoFormatIsoYear;
  const factory quarter({ChronoPadding padding}) = ChronoFormatQuarter;
  const factory month({ChronoPadding padding}) = ChronoFormatMonth;
  const factory day({ChronoPadding padding}) = ChronoFormatDay;
  const factory weekFromSun({ChronoPadding padding}) = ChronoFormatWeekFromSun;
  const factory weekFromMon({ChronoPadding padding}) = ChronoFormatWeekFromMon;
  const factory isoWeek({ChronoPadding padding}) = ChronoFormatIsoWeek;
  const factory numDaysFromSun({ChronoPadding padding}) =
      ChronoFormatNumDaysFromSun;
  const factory weekday({ChronoPadding padding}) = ChronoFormatWeekday;
  const factory ordinal({ChronoPadding padding}) = ChronoFormatOrdinal;
  const factory hour({ChronoPadding padding}) = ChronoFormatHour;
  const factory hour12({ChronoPadding padding}) = ChronoFormatHour12;
  const factory minute({ChronoPadding padding}) = ChronoFormatMinute;
  const factory second({ChronoPadding padding}) = ChronoFormatSecond;
  const factory nanosecond({ChronoPadding padding}) = ChronoFormatNanosecond;
  const factory monthName(ChronoFormatLength length) = ChronoFormatMonthName;
  const factory weekdayName(ChronoFormatLength length) =
      ChronoFormatWeekdayName;
  const factory amPm(ChronoCasing casing) = ChronoFormatAmPm;
  const factory subsecond(ChronoSubsecondAccuracy accuracy) =
      ChronoFormatSubsecond;
  const factory timezoneName() = ChronoFormatTimezoneName;
  const factory timezoneOffset({
    TimezoneOffsetPrecision precision,
    bool allowZulu,
    bool printColon,
  }) = ChronoFormatTimezoneOffset;
}

// DateTime

/// A [ChronoFormatItem] that is used for formatting and parsing [CDateTime]s.
sealed class CDateTimeFormatItem extends ChronoFormatItem
    implements ZonedDateTimeFormatItem {
  const factory literal(String text) = ChronoFormatItemLiteral;
  const factory space(String text) = ChronoFormatItemSpace;
  const factory year({YearFormat format, ChronoPadding padding}) =
      ChronoFormatYear;
  const factory isoYear({YearFormat format, ChronoPadding padding}) =
      ChronoFormatIsoYear;
  const factory quarter({ChronoPadding padding}) = ChronoFormatQuarter;
  const factory month({ChronoPadding padding}) = ChronoFormatMonth;
  const factory day({ChronoPadding padding}) = ChronoFormatDay;
  const factory weekFromSun({ChronoPadding padding}) = ChronoFormatWeekFromSun;
  const factory weekFromMon({ChronoPadding padding}) = ChronoFormatWeekFromMon;
  const factory isoWeek({ChronoPadding padding}) = ChronoFormatIsoWeek;
  const factory numDaysFromSun({ChronoPadding padding}) =
      ChronoFormatNumDaysFromSun;
  const factory weekday({ChronoPadding padding}) = ChronoFormatWeekday;
  const factory ordinal({ChronoPadding padding}) = ChronoFormatOrdinal;
  const factory hour({ChronoPadding padding}) = ChronoFormatHour;
  const factory hour12({ChronoPadding padding}) = ChronoFormatHour12;
  const factory minute({ChronoPadding padding}) = ChronoFormatMinute;
  const factory second({ChronoPadding padding}) = ChronoFormatSecond;
  const factory nanosecond({ChronoPadding padding}) = ChronoFormatNanosecond;
  const factory monthName(ChronoFormatLength length) = ChronoFormatMonthName;
  const factory weekdayName(ChronoFormatLength length) =
      ChronoFormatWeekdayName;
  const factory amPm(ChronoCasing casing) = ChronoFormatAmPm;
  const factory subsecond(ChronoSubsecondAccuracy accuracy) =
      ChronoFormatSubsecond;
}

// Date

/// A [ChronoFormatItem] that is used for formatting and parsing [Date]s.
sealed class DateFormatItem extends CDateTimeFormatItem {
  const factory literal(String text) = ChronoFormatItemLiteral;
  const factory space(String text) = ChronoFormatItemSpace;
  const factory year({YearFormat format, ChronoPadding padding}) =
      ChronoFormatYear;
  const factory isoYear({YearFormat format, ChronoPadding padding}) =
      ChronoFormatIsoYear;
  const factory quarter({ChronoPadding padding}) = ChronoFormatQuarter;
  const factory month({ChronoPadding padding}) = ChronoFormatMonth;
  const factory day({ChronoPadding padding}) = ChronoFormatDay;
  const factory weekFromSun({ChronoPadding padding}) = ChronoFormatWeekFromSun;
  const factory weekFromMon({ChronoPadding padding}) = ChronoFormatWeekFromMon;
  const factory isoWeek({ChronoPadding padding}) = ChronoFormatIsoWeek;
  const factory numDaysFromSun({ChronoPadding padding}) =
      ChronoFormatNumDaysFromSun;
  const factory weekday({ChronoPadding padding}) = ChronoFormatWeekday;
  const factory ordinal({ChronoPadding padding}) = ChronoFormatOrdinal;
  const factory monthName(ChronoFormatLength length) = ChronoFormatMonthName;
  const factory weekdayName(ChronoFormatLength length) =
      ChronoFormatWeekdayName;
}

sealed class TimeFormatItem extends CDateTimeFormatItem {
  const factory literal(String text) = ChronoFormatItemLiteral;
  const factory space(String text) = ChronoFormatItemSpace;
  const factory hour({ChronoPadding padding}) = ChronoFormatHour;
  const factory hour12({ChronoPadding padding}) = ChronoFormatHour12;
  const factory minute({ChronoPadding padding}) = ChronoFormatMinute;
  const factory second({ChronoPadding padding}) = ChronoFormatSecond;
  const factory nanosecond({ChronoPadding padding}) = ChronoFormatNanosecond;
  const factory amPm(ChronoCasing casing) = ChronoFormatAmPm;
  const factory subsecond(ChronoSubsecondAccuracy accuracy) =
      ChronoFormatSubsecond;
}

/// Gregorian year.
class const ChronoFormatYear({final YearFormat format = .full, super.padding})
    extends ChronoFormatItemNumeric
    implements DateFormatItem;

/// Year in the ISO week date.
class const ChronoFormatIsoYear({
  final YearFormat format = .full,
  super.padding,
}) extends ChronoFormatItemNumeric implements DateFormatItem;

/// How to format [ChronoFormatYear] and [ChronoFormatIsoYear].
enum YearFormat {
  /// The full year number (FW=4, PW=∞).
  ///
  /// May accept years before 1 BCE or after 9999 CE, given an initial sign (+/-).
  full,

  /// The year number divided by 100 (century number; FW=PW=2). Implies a
  /// non-negative year.
  div100,

  /// The year number modulo 100 (FW=PW=2). Cannot be negative.
  mod100,
}

/// Quarter (FW=PW=1).
class const ChronoFormatQuarter({super.padding})
    extends ChronoFormatItemNumeric
    implements DateFormatItem;

/// Month (FW=PW=2).
class const ChronoFormatMonth({super.padding})
    extends ChronoFormatItemNumeric
    implements DateFormatItem;

/// Month names.
///
/// Prints a name in title case, reads the name in any case.
class const ChronoFormatMonthName(final ChronoFormatLength length)
    extends ChronoFormatItemFixed
    implements DateFormatItem;

/// Weekday names.
///
/// Prints a name in title case, reads the name in any case.
class const ChronoFormatWeekdayName(final ChronoFormatLength length)
    extends ChronoFormatItemFixed
    implements DateFormatItem;

/// Day of the month (FW=PW=2).
class const ChronoFormatDay({super.padding})
    extends ChronoFormatItemNumeric
    implements DateFormatItem;

// TODO(JonasWanke): merge?
/// Week number, where week 1 starts at the first Sunday of January (FW=PW=2).
class const ChronoFormatWeekFromSun({super.padding})
    extends ChronoFormatItemNumeric
    implements DateFormatItem;

/// Week number, where week 1 starts at the first Monday of January (FW=PW=2).
class const ChronoFormatWeekFromMon({super.padding})
    extends ChronoFormatItemNumeric
    implements DateFormatItem;

/// Week number in the ISO week date (FW=PW=2).
class const ChronoFormatIsoWeek({super.padding})
    extends ChronoFormatItemNumeric
    implements DateFormatItem;

// TODO(JonasWanke): merge?
/// Day of the week, where Sunday = 0 and Saturday = 6 (FW=PW=1).
class const ChronoFormatNumDaysFromSun({super.padding})
    extends ChronoFormatItemNumeric
    implements DateFormatItem;

/// ISO weekday number, where Monday = 1 and Sunday = 7 (FW=PW=1).
class const ChronoFormatWeekday({super.padding})
    extends ChronoFormatItemNumeric
    implements DateFormatItem;

/// Day of the year (FW=PW=3).
class const ChronoFormatOrdinal({super.padding})
    extends ChronoFormatItemNumeric
    implements DateFormatItem;

// Time

/// Hour number in the 24-hour clocks (FW=PW=2).
class const ChronoFormatHour({super.padding})
    extends ChronoFormatItemNumeric
    implements TimeFormatItem;

/// AM/PM
class const ChronoFormatAmPm(final ChronoCasing casing)
    extends ChronoFormatItemFixed
    implements TimeFormatItem;

enum ChronoCasing {
  /// Prints in lower case, reads in any case.
  lower,

  /// Prints in upper case, reads in any case.
  upper,
}

/// Hour number in the 12-hour clocks (FW=PW=2).
class const ChronoFormatHour12({super.padding})
    extends ChronoFormatItemNumeric
    implements TimeFormatItem;

/// The number of minutes since the last whole hour (FW=PW=2).
class const ChronoFormatMinute({super.padding})
    extends ChronoFormatItemNumeric
    implements TimeFormatItem;

/// The number of seconds since the last whole minute (FW=PW=2).
class const ChronoFormatSecond({super.padding})
    extends ChronoFormatItemNumeric
    implements TimeFormatItem;

/// The number of nanoseconds since the last whole second (FW=PW=9).
///
/// Note that this is *not* left-aligned, see also [ChronoFormatSubsecond].
class const ChronoFormatNanosecond({super.padding})
    extends ChronoFormatItemNumeric
    implements TimeFormatItem;

/// An optional dot plus one or more digits for millis/micros/nanos.
class const ChronoFormatSubsecond(final ChronoSubsecondAccuracy accuracy)
    extends ChronoFormatItemFixed
    implements TimeFormatItem;

enum ChronoSubsecondAccuracy {
  /// May print nothing, 3, 6, or 9 digits according to the available accuracy.
  variable,
  millis,
  micros,
  nanos,
}

// Instant

/// The number of non-leap seconds since the midnight UTC on January 1, 1970
/// (FW=1, PW=∞).
///
/// For formatting, it assumes UTC upon the absence of time zone offset.
class const ChronoFormatTimestamp({super.padding})
    extends ChronoFormatItemNumeric;

// ZonedDateTime

/// Timezone name.
///
/// For a [ZonedDateTime], this is the `toString()` of its [Offset], e.g.,
/// “EDT”, “+09:30”, or “UTC”.
///
/// It does not support parsing, its use in the parser is an immediate failure.
class const ChronoFormatTimezoneName()
    extends ChronoFormatItemFixed
    implements ZonedDateTimeFormatItem;

/// Offset from the local time to UTC (`+09:00` or `-04` or `+00:00:00`).
///
/// In the parser, the colon can be omitted and/or surrounded with any amount of
/// whitespace.
///
/// The offset is limited from `-24:00:00` to `+24:00:00` (exclusive), which is
/// the same as [FixedOffset]'s range.
class const ChronoFormatTimezoneOffset({
  final TimezoneOffsetPrecision precision = .minutes,

  /// Whether to allow `Z` (or `z`) for the zero offset in parsing.
  final bool allowZulu = true,

  /// Whether to print the colon in the offset.
  ///
  /// Parsing allows the colon to be omitted regardless of this flag.
  final bool printColon = true,
}) extends ChronoFormatItemFixed implements ZonedDateTimeFormatItem;

enum TimezoneOffsetPrecision {
  hours,
  optionalMinutes,
  minutes,
  optionalMinutesAndSeconds,
  optionalSeconds,
  seconds,
}

/// Specific formatting options for seconds.
///
/// See [ZonedDateTime.rfc3339Format] for usage.
enum ChronoSecondsFormat {
  /// Format whole seconds only, with no decimal point or subseconds.
  seconds,

  /// Use fixed 3 subsecond digits.
  ///
  /// This corresponds to [ChronoSubsecondAccuracy.millis].
  millis,

  /// Use fixed 6 subsecond digits.
  ///
  /// This corresponds to [ChronoSubsecondAccuracy.micros].
  micros,

  /// Use fixed 9 subsecond digits.
  ///
  /// This corresponds to [ChronoSubsecondAccuracy.nanos].
  nanos,

  /// Automatically select one of [seconds], [millis], [micros], and [nanos] to
  /// display all available non-zero sub-second digits.
  ///
  /// This corresponds to [ChronoSubsecondAccuracy.variable].
  variable,
}
