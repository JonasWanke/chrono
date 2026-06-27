import '../../chrono.dart';

// Shared

/// A single formatting item.
///
/// This is used for both formatting and parsing.
sealed class ChronoFormatItem {
  const ChronoFormatItem();

  const factory ChronoFormatItem.literal(String text) = ChronoFormatItemLiteral;
  const factory ChronoFormatItem.space(String text) = ChronoFormatItemSpace;
  const factory ChronoFormatItem.year({
    YearFormat format,
    ChronoPadding padding,
  }) = ChronoFormatYear;
  const factory ChronoFormatItem.isoYear({
    YearFormat format,
    ChronoPadding padding,
  }) = ChronoFormatIsoYear;
  const factory ChronoFormatItem.quarter({ChronoPadding padding}) =
      ChronoFormatQuarter;
  const factory ChronoFormatItem.month({ChronoPadding padding}) =
      ChronoFormatMonth;
  const factory ChronoFormatItem.day({ChronoPadding padding}) = ChronoFormatDay;
  const factory ChronoFormatItem.weekFromSun({ChronoPadding padding}) =
      ChronoFormatWeekFromSun;
  const factory ChronoFormatItem.weekFromMon({ChronoPadding padding}) =
      ChronoFormatWeekFromMon;
  const factory ChronoFormatItem.isoWeek({ChronoPadding padding}) =
      ChronoFormatIsoWeek;
  const factory ChronoFormatItem.numDaysFromSun({ChronoPadding padding}) =
      ChronoFormatNumDaysFromSun;
  const factory ChronoFormatItem.weekday({ChronoPadding padding}) =
      ChronoFormatWeekday;
  const factory ChronoFormatItem.ordinal({ChronoPadding padding}) =
      ChronoFormatOrdinal;
  const factory ChronoFormatItem.hour({ChronoPadding padding}) =
      ChronoFormatHour;
  const factory ChronoFormatItem.hour12({ChronoPadding padding}) =
      ChronoFormatHour12;
  const factory ChronoFormatItem.minute({ChronoPadding padding}) =
      ChronoFormatMinute;
  const factory ChronoFormatItem.second({ChronoPadding padding}) =
      ChronoFormatSecond;
  const factory ChronoFormatItem.nanosecond({ChronoPadding padding}) =
      ChronoFormatNanosecond;
  const factory ChronoFormatItem.timestamp({ChronoPadding padding}) =
      ChronoFormatTimestamp;
  const factory ChronoFormatItem.monthName(ChronoFormatLength length) =
      ChronoFormatMonthName;
  const factory ChronoFormatItem.weekdayName(ChronoFormatLength length) =
      ChronoFormatWeekdayName;
  const factory ChronoFormatItem.amPm(ChronoCasing casing) = ChronoFormatAmPm;
  const factory ChronoFormatItem.subsecond(ChronoSubsecondAccuracy accuracy) =
      ChronoFormatSubsecond;
  const factory ChronoFormatItem.timezoneName() = ChronoFormatTimezoneName;
  const factory ChronoFormatItem.timezoneOffset({
    TimezoneOffsetPrecision precision,
    bool allowZulu,
    bool printColon,
  }) = ChronoFormatTimezoneOffset;
  const factory ChronoFormatItem.rfc2822() = ChronoFormatRFC2822;
  const factory ChronoFormatItem.rfc3339() = ChronoFormatRFC3339;
}

/// A literally printed and parsed text.
class ChronoFormatItemLiteral extends ChronoFormatItem
    implements DateFormatItem, TimeFormatItem {
  const ChronoFormatItemLiteral(this.text);

  final String text;
}

/// Whitespace. Prints literally but reads zero or more whitespace.
class ChronoFormatItemSpace extends ChronoFormatItem
    implements DateFormatItem, TimeFormatItem {
  const ChronoFormatItemSpace(this.text);

  final String text;
}

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
sealed class ChronoFormatItemNumeric extends ChronoFormatItem {
  const ChronoFormatItemNumeric({this.padding = .zero});

  final ChronoPadding padding;
}

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
sealed class ChronoFormatItemFixed extends ChronoFormatItem {
  const ChronoFormatItemFixed();
}

/// Issues a formatting error. Used to signal an invalid format string.
// TODO(JonasWanke): Is this necessary?
class ChronoFormatItemError extends ChronoFormatItem {}

abstract interface class ChronoFormattable<I extends ChronoFormatItem> {
  @override
  String toString([List<I> items]);
}

// DateTime

/// A [ChronoFormatItem] that is used for formatting and parsing [CDateTime]s.
sealed class CDateTimeFormatItem extends ChronoFormatItem {
  const factory CDateTimeFormatItem.literal(String text) =
      ChronoFormatItemLiteral;
  const factory CDateTimeFormatItem.space(String text) = ChronoFormatItemSpace;
  const factory CDateTimeFormatItem.year({
    YearFormat format,
    ChronoPadding padding,
  }) = ChronoFormatYear;
  const factory CDateTimeFormatItem.isoYear({
    YearFormat format,
    ChronoPadding padding,
  }) = ChronoFormatIsoYear;
  const factory CDateTimeFormatItem.quarter({ChronoPadding padding}) =
      ChronoFormatQuarter;
  const factory CDateTimeFormatItem.month({ChronoPadding padding}) =
      ChronoFormatMonth;
  const factory CDateTimeFormatItem.day({ChronoPadding padding}) =
      ChronoFormatDay;
  const factory CDateTimeFormatItem.weekFromSun({ChronoPadding padding}) =
      ChronoFormatWeekFromSun;
  const factory CDateTimeFormatItem.weekFromMon({ChronoPadding padding}) =
      ChronoFormatWeekFromMon;
  const factory CDateTimeFormatItem.isoWeek({ChronoPadding padding}) =
      ChronoFormatIsoWeek;
  const factory CDateTimeFormatItem.numDaysFromSun({ChronoPadding padding}) =
      ChronoFormatNumDaysFromSun;
  const factory CDateTimeFormatItem.weekday({ChronoPadding padding}) =
      ChronoFormatWeekday;
  const factory CDateTimeFormatItem.ordinal({ChronoPadding padding}) =
      ChronoFormatOrdinal;
  const factory CDateTimeFormatItem.hour({ChronoPadding padding}) =
      ChronoFormatHour;
  const factory CDateTimeFormatItem.hour12({ChronoPadding padding}) =
      ChronoFormatHour12;
  const factory CDateTimeFormatItem.minute({ChronoPadding padding}) =
      ChronoFormatMinute;
  const factory CDateTimeFormatItem.second({ChronoPadding padding}) =
      ChronoFormatSecond;
  const factory CDateTimeFormatItem.nanosecond({ChronoPadding padding}) =
      ChronoFormatNanosecond;
  const factory CDateTimeFormatItem.monthName(ChronoFormatLength length) =
      ChronoFormatMonthName;
  const factory CDateTimeFormatItem.weekdayName(ChronoFormatLength length) =
      ChronoFormatWeekdayName;
  const factory CDateTimeFormatItem.amPm(ChronoCasing casing) =
      ChronoFormatAmPm;
  const factory CDateTimeFormatItem.subsecond(
    ChronoSubsecondAccuracy accuracy,
  ) = ChronoFormatSubsecond;
}

// Date

/// A [ChronoFormatItem] that is used for formatting and parsing [Date]s.
sealed class DateFormatItem extends CDateTimeFormatItem {
  const factory DateFormatItem.literal(String text) = ChronoFormatItemLiteral;
  const factory DateFormatItem.space(String text) = ChronoFormatItemSpace;
  const factory DateFormatItem.year({
    YearFormat format,
    ChronoPadding padding,
  }) = ChronoFormatYear;
  const factory DateFormatItem.isoYear({
    YearFormat format,
    ChronoPadding padding,
  }) = ChronoFormatIsoYear;
  const factory DateFormatItem.quarter({ChronoPadding padding}) =
      ChronoFormatQuarter;
  const factory DateFormatItem.month({ChronoPadding padding}) =
      ChronoFormatMonth;
  const factory DateFormatItem.day({ChronoPadding padding}) = ChronoFormatDay;
  const factory DateFormatItem.weekFromSun({ChronoPadding padding}) =
      ChronoFormatWeekFromSun;
  const factory DateFormatItem.weekFromMon({ChronoPadding padding}) =
      ChronoFormatWeekFromMon;
  const factory DateFormatItem.isoWeek({ChronoPadding padding}) =
      ChronoFormatIsoWeek;
  const factory DateFormatItem.numDaysFromSun({ChronoPadding padding}) =
      ChronoFormatNumDaysFromSun;
  const factory DateFormatItem.weekday({ChronoPadding padding}) =
      ChronoFormatWeekday;
  const factory DateFormatItem.ordinal({ChronoPadding padding}) =
      ChronoFormatOrdinal;
  const factory DateFormatItem.monthName(ChronoFormatLength length) =
      ChronoFormatMonthName;
  const factory DateFormatItem.weekdayName(ChronoFormatLength length) =
      ChronoFormatWeekdayName;
}

sealed class TimeFormatItem extends CDateTimeFormatItem {
  const factory TimeFormatItem.literal(String text) = ChronoFormatItemLiteral;
  const factory TimeFormatItem.space(String text) = ChronoFormatItemSpace;
  const factory TimeFormatItem.hour({ChronoPadding padding}) = ChronoFormatHour;
  const factory TimeFormatItem.hour12({ChronoPadding padding}) =
      ChronoFormatHour12;
  const factory TimeFormatItem.minute({ChronoPadding padding}) =
      ChronoFormatMinute;
  const factory TimeFormatItem.second({ChronoPadding padding}) =
      ChronoFormatSecond;
  const factory TimeFormatItem.nanosecond({ChronoPadding padding}) =
      ChronoFormatNanosecond;
  const factory TimeFormatItem.amPm(ChronoCasing casing) = ChronoFormatAmPm;
  const factory TimeFormatItem.subsecond(ChronoSubsecondAccuracy accuracy) =
      ChronoFormatSubsecond;
}

/// Gregorian year.
class ChronoFormatYear extends ChronoFormatItemNumeric
    implements DateFormatItem {
  const ChronoFormatYear({this.format = .full, super.padding});

  final YearFormat format;
}

/// Year in the ISO week date.
class ChronoFormatIsoYear extends ChronoFormatItemNumeric
    implements DateFormatItem {
  const ChronoFormatIsoYear({this.format = .full, super.padding});

  final YearFormat format;
}

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
class ChronoFormatQuarter extends ChronoFormatItemNumeric
    implements DateFormatItem {
  const ChronoFormatQuarter({super.padding});
}

/// Month (FW=PW=2).
class ChronoFormatMonth extends ChronoFormatItemNumeric
    implements DateFormatItem {
  const ChronoFormatMonth({super.padding});
}

/// Month names.
///
/// Prints a name in title case, reads the name in any case.
class ChronoFormatMonthName extends ChronoFormatItemFixed
    implements DateFormatItem {
  const ChronoFormatMonthName(this.length);

  final ChronoFormatLength length;
}

/// Weekday names.
///
/// Prints a name in title case, reads the name in any case.
class ChronoFormatWeekdayName extends ChronoFormatItemFixed
    implements DateFormatItem {
  const ChronoFormatWeekdayName(this.length);

  final ChronoFormatLength length;
}

/// Day of the month (FW=PW=2).
class ChronoFormatDay extends ChronoFormatItemNumeric
    implements DateFormatItem {
  const ChronoFormatDay({super.padding});
}

// TODO(JonasWanke): merge?
/// Week number, where week 1 starts at the first Sunday of January (FW=PW=2).
class ChronoFormatWeekFromSun extends ChronoFormatItemNumeric
    implements DateFormatItem {
  const ChronoFormatWeekFromSun({super.padding});
}

/// Week number, where week 1 starts at the first Monday of January (FW=PW=2).
class ChronoFormatWeekFromMon extends ChronoFormatItemNumeric
    implements DateFormatItem {
  const ChronoFormatWeekFromMon({super.padding});
}

/// Week number in the ISO week date (FW=PW=2).
class ChronoFormatIsoWeek extends ChronoFormatItemNumeric
    implements DateFormatItem {
  const ChronoFormatIsoWeek({super.padding});
}

// TODO(JonasWanke): merge?
/// Day of the week, where Sunday = 0 and Saturday = 6 (FW=PW=1).
class ChronoFormatNumDaysFromSun extends ChronoFormatItemNumeric
    implements DateFormatItem {
  const ChronoFormatNumDaysFromSun({super.padding});
}

/// ISO weekday number, where Monday = 1 and Sunday = 7 (FW=PW=1).
class ChronoFormatWeekday extends ChronoFormatItemNumeric
    implements DateFormatItem {
  const ChronoFormatWeekday({super.padding});
}

/// Day of the year (FW=PW=3).
class ChronoFormatOrdinal extends ChronoFormatItemNumeric
    implements DateFormatItem {
  const ChronoFormatOrdinal({super.padding});
}

// Time

/// Hour number in the 24-hour clocks (FW=PW=2).
class ChronoFormatHour extends ChronoFormatItemNumeric
    implements TimeFormatItem {
  const ChronoFormatHour({super.padding});
}

/// AM/PM
class ChronoFormatAmPm extends ChronoFormatItemFixed implements TimeFormatItem {
  const ChronoFormatAmPm(this.casing);

  final ChronoCasing casing;
}

enum ChronoCasing {
  /// Prints in lower case, reads in any case.
  lower,

  /// Prints in upper case, reads in any case.
  upper,
}

/// Hour number in the 12-hour clocks (FW=PW=2).
class ChronoFormatHour12 extends ChronoFormatItemNumeric
    implements TimeFormatItem {
  const ChronoFormatHour12({super.padding});
}

/// The number of minutes since the last whole hour (FW=PW=2).
class ChronoFormatMinute extends ChronoFormatItemNumeric
    implements TimeFormatItem {
  const ChronoFormatMinute({super.padding});
}

/// The number of seconds since the last whole minute (FW=PW=2).
class ChronoFormatSecond extends ChronoFormatItemNumeric
    implements TimeFormatItem {
  const ChronoFormatSecond({super.padding});
}

/// The number of nanoseconds since the last whole second (FW=PW=9).
///
/// Note that this is *not* left-aligned, see also [ChronoFormatSubsecond].
class ChronoFormatNanosecond extends ChronoFormatItemNumeric
    implements TimeFormatItem {
  const ChronoFormatNanosecond({super.padding});
}

/// An optional dot plus one or more digits for millis/micros/nanos.
class ChronoFormatSubsecond extends ChronoFormatItemFixed
    implements TimeFormatItem {
  const ChronoFormatSubsecond(this.accuracy);

  final ChronoSubsecondAccuracy accuracy;
}

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
class ChronoFormatTimestamp extends ChronoFormatItemNumeric {
  const ChronoFormatTimestamp({super.padding});
}

// ZonedDateTime

/// Timezone name.
///
/// It does not support parsing, its use in the parser is an immediate failure.
class ChronoFormatTimezoneName extends ChronoFormatItemFixed {
  const ChronoFormatTimezoneName();
}

/// Offset from the local time to UTC (`+09:00` or `-04` or `+00:00:00`).
///
/// In the parser, the colon can be omitted and/or surrounded with any amount of
/// whitespace.
///
/// The offset is limited from `-24:00:00` to `+24:00:00` (exclusive), which is
/// the same as [FixedOffset]'s range.
class ChronoFormatTimezoneOffset extends ChronoFormatItemFixed {
  const ChronoFormatTimezoneOffset({
    this.precision = .minutes,
    this.allowZulu = true,
    this.printColon = true,
  });

  final TimezoneOffsetPrecision precision;

  /// Whether to allow `Z` (or `z`) for the zero offset in parsing.
  final bool allowZulu;

  /// Whether to print the colon in the offset.
  ///
  /// Parsing allows the colon to be omitted regardless of this flag.
  final bool printColon;
}

enum TimezoneOffsetPrecision {
  hours,
  optionalMinutes,
  minutes,
  optionalMinutesAndSeconds,
  optionalSeconds,
  seconds,
}

/// RFC 2822 date and time syntax.
///
/// Commonly used for email and MIME date and time.
class ChronoFormatRFC2822 extends ChronoFormatItemFixed {
  const ChronoFormatRFC2822();
}

/// RFC 3339 & ISO 8601 date and time syntax.
class ChronoFormatRFC3339 extends ChronoFormatItemFixed {
  const ChronoFormatRFC3339();
}

/// Specific formatting options for seconds.
///
/// See [TimeZone.to_rfc3339_opts] for usage.
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
