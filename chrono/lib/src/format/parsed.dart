import '../../chrono.dart';

/// A type to hold parsed fields of date, time, and timezone offset that can
/// check all fields are consistent.
///
/// There are three classes of methods:
///
/// - `set*` methods to set fields you have available. They do a basic range check, and if the
///   same field is set more than once it is checked for consistency.
///
/// - `to*` methods try to make a concrete date and time value out of set fields.
///   They fully check that all fields are consistent and whether the date/datetime exists.
///
/// - Methods to inspect the parsed fields.
///
/// `Parsed` is used internally by all parsing functions in chrono. It is a public type so that it
/// can be used to write custom parsers that reuse the resolving algorithm, or to inspect the
/// results of a string parsed with chrono without converting it to concrete types.
///
/// # Resolving algorithm
///
/// Resolving date/time parts is littered with lots of corner cases, which is why common date/time
/// parsers do not implement it correctly.
///
/// Chrono provides a complete resolution algorithm that checks all fields for consistency via the
/// `Parsed` type.
///
/// As an easy example, consider RFC 2822. The [RFC 2822 date and time format] has a day of the week
/// part, which should be consistent with the other date parts. But a `strptime`-based parse would
/// happily accept inconsistent input:
///
/// ```python
/// >>> import time
/// >>> time.strptime('Wed, 31 Dec 2014 04:26:40 +0000',
///                   '%a, %d %b %Y %H:%M:%S +0000')
/// time.struct_time(tm_year=2014, tm_mon=12, tm_mday=31,
///                  tm_hour=4, tm_min=26, tm_sec=40,
///                  tm_wday=2, tm_yday=365, tm_isdst=-1)
/// >>> time.strptime('Thu, 31 Dec 2014 04:26:40 +0000',
///                   '%a, %d %b %Y %H:%M:%S +0000')
/// time.struct_time(tm_year=2014, tm_mon=12, tm_mday=31,
///                  tm_hour=4, tm_min=26, tm_sec=40,
///                  tm_wday=3, tm_yday=365, tm_isdst=-1)
/// ```
///
/// [RFC 2822 date and time format]: https://tools.ietf.org/html/rfc2822#section-3.3
///
/// # Example
///
/// Let's see how `Parsed` correctly detects the second RFC 2822 string from before is inconsistent.
///
/// ```
/// # #[cfg(feature = "alloc")] {
/// use chrono::format::{ParseErrorKind, Parsed};
/// use chrono::Weekday;
///
/// let mut parsed = Parsed::new();
/// parsed.set_weekday(Weekday::Wed)?;
/// parsed.set_day(31)?;
/// parsed.set_month(12)?;
/// parsed.set_year(2014)?;
/// parsed.set_hour(4)?;
/// parsed.set_minute(26)?;
/// parsed.set_second(40)?;
/// parsed.set_offset(0)?;
/// let dt = parsed.to_datetime()?;
/// assert_eq!(dt.to_rfc2822(), "Wed, 31 Dec 2014 04:26:40 +0000");
///
/// let mut parsed = Parsed::new();
/// parsed.set_weekday(Weekday::Thu)?; // changed to the wrong day
/// parsed.set_day(31)?;
/// parsed.set_month(12)?;
/// parsed.set_year(2014)?;
/// parsed.set_hour(4)?;
/// parsed.set_minute(26)?;
/// parsed.set_second(40)?;
/// parsed.set_offset(0)?;
/// let result = parsed.to_datetime();
///
/// assert!(result.is_err());
/// if let Err(error) = result {
///     assert_eq!(error.kind(), ParseErrorKind::Impossible);
/// }
/// # }
/// # Ok::<(), chrono::ParseError>(())
/// ```
///
/// The same using chrono's built-in parser for RFC 2822 (the [RFC2822 formatting item]) and
/// [`format::parse()`] showing how to inspect a field on failure.
///
/// [RFC2822 formatting item]: crate::format::Fixed::RFC2822
/// [`format::parse()`]: crate::format::parse()
///
/// ```
/// # #[cfg(feature = "alloc")] {
/// use chrono::format::{parse, Fixed, Item, Parsed};
/// use chrono::Weekday;
///
/// let rfc_2822 = [Item::Fixed(Fixed::RFC2822)];
///
/// let mut parsed = Parsed::new();
/// parse(&mut parsed, "Wed, 31 Dec 2014 04:26:40 +0000", rfc_2822.iter())?;
/// let dt = parsed.to_datetime()?;
///
/// assert_eq!(dt.to_rfc2822(), "Wed, 31 Dec 2014 04:26:40 +0000");
///
/// let mut parsed = Parsed::new();
/// parse(&mut parsed, "Thu, 31 Dec 2014 04:26:40 +0000", rfc_2822.iter())?;
/// let result = parsed.to_datetime();
///
/// assert!(result.is_err());
/// if result.is_err() {
///     // What is the weekday?
///     assert_eq!(parsed.weekday(), Some(Weekday::Thu));
/// }
/// # }
/// # Ok::<(), chrono::ParseError>(())
/// ```
class ChronoParsed {
  Year? _year;
  Year? get year => _year;

  /// Set the [year] field to the given value.
  ///
  /// The value can be negative, unlike [yearDiv100] and [yearMod100].
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange] if [value] is outside the range of an `i32`.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set year(Year value) {
    _throwIfInconsistent(year, value);
    _year = value;
  }

  int? _yearDiv100;
  int? get yearDiv100 => _yearDiv100;

  /// Set the [yearDiv100] field to the given value.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is negative.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set yearDiv100(int value) {
    if (value < 0) throw const ChronoParseException(.outOfRange);
    _throwIfInconsistent(yearDiv100, value);
    _yearDiv100 = value;
  }

  int? _yearMod100;
  int? get yearMod100 => _yearMod100;

  /// Set the [yearMod100] field to the given value.
  ///
  /// When set, it implies that the year is not negative.
  ///
  /// If this field is set while the [yearDiv100] field is missing (and the full
  /// [year] field is also not set), it assumes a default value for the
  /// [yearDiv100] field. The default is 19 when `yearMod100 >= 70` and 20
  /// otherwise.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is negative or if it is greater than 99.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set yearMod100(int value) {
    if (value < 0 || value > 99) throw const ChronoParseException(.outOfRange);
    _throwIfInconsistent(yearMod100, value);
    _yearMod100 = value;
  }

  Year? _isoYear;
  Year? get isoYear => _isoYear;

  /// Set the [isoYear] field, which is part of an ISO 8601 week date, to the
  /// given value.
  ///
  /// The value can be negative, unlike the [isoYearDiv100] and [isoYearMod100]
  /// fields.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set isoYear(Year value) {
    _throwIfInconsistent(isoYear, value);
    _isoYear = value;
  }

  int? _isoYearDiv100;
  int? get isoYearDiv100 => _isoYearDiv100;

  /// Set the [isoYearDiv100] field, which is part of an ISO 8601 week date, to
  /// the given value.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is negative.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set isoYearDiv100(int value) {
    if (value < 0) throw const ChronoParseException(.outOfRange);
    _throwIfInconsistent(isoYearDiv100, value);
    _isoYearDiv100 = value;
  }

  int? _isoYearMod100;
  int? get isoYearMod100 => _isoYearMod100;

  /// Set the [isoYearMod100] field, which is part of an ISO 8601 week date, to
  /// the given value.
  ///
  /// When set, it implies that the year is not negative.
  ///
  /// If this field is set while the [isoYearDiv100] field is missing (and the
  /// full [isoYear] field is also not set), it assumes a default value for the
  /// [isoYearDiv100] field. The default is 19 when `isoYearMod100 >= 70` and 20
  /// otherwise.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is negative or if it is greater than 99.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set isoYearMod100(int value) {
    if (value < 0 || value > 99) throw const ChronoParseException(.outOfRange);
    _throwIfInconsistent(isoYearMod100, value);
    _isoYearMod100 = value;
  }

  Quarter? _quarter;
  Quarter? get quarter => _quarter;

  /// Set the [quarter] field to the given value.
  ///
  /// Quarter 1 starts in January.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is not in the range 1 – 4.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set quarter(Quarter value) {
    _throwIfInconsistent(quarter, value);
    _quarter = value;
  }

  Month? _month;
  Month? get month => _month;

  /// Set the [month] field to the given value.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is not in the range 1 – 12.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set month(Month value) {
    _throwIfInconsistent(month, value);
    _month = value;
  }

  int? _weekFromSun;
  int? get weekFromSun => _weekFromSun;

  /// Set the [weekFromSun] week number field to the given value.
  ///
  /// Week 1 starts at the first Sunday of January.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is not in the range 0 – 53.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set weekFromSun(int value) {
    if (value < 0 || value > 53) throw const ChronoParseException(.outOfRange);
    _throwIfInconsistent(weekFromSun, value);
    _weekFromSun = value;
  }

  int? _weekFromMon;
  int? get weekFromMon => _weekFromMon;

  /// Set the [weekFromMon] week number field to the given value.
  ///
  /// Week 1 starts at the first Monday of January.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is not in the range 0 – 53.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set weekFromMon(int value) {
    if (value < 0 || value > 53) throw const ChronoParseException(.outOfRange);
    _throwIfInconsistent(weekFromMon, value);
    _weekFromMon = value;
  }

  int? _isoWeek;
  int? get isoWeek => _isoWeek;

  /// Set the [isoWeek] field for an ISO 8601 week date to the given value.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is not in the range 1 – 53.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set isoWeek(int value) {
    if (value < 1 || value > 53) throw const ChronoParseException(.outOfRange);
    _throwIfInconsistent(isoWeek, value);
    _isoWeek = value;
  }

  Weekday? _weekday;
  Weekday? get weekday => _weekday;

  /// Set the [weekday] field to the given value.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set weekday(Weekday value) {
    _throwIfInconsistent(weekday, value);
    _weekday = value;
  }

  int? _ordinal;
  int? get ordinal => _ordinal;

  /// Set the [ordinal] (day of the year) field to the given value.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is not in the range 1 – 366.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set ordinal(int value) {
    if (value < 1 || value > Days.perLeapYear) {
      throw const ChronoParseException(.outOfRange);
    }
    _throwIfInconsistent(ordinal, value);
    _ordinal = value;
  }

  int? _day;
  int? get day => _day;

  /// Set the [day] of the month field to the given value.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is not in the range 1 – 31.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set day(int value) {
    if (value < 1 || value > 31) throw const ChronoParseException(.outOfRange);
    _throwIfInconsistent(day, value);
    _day = value;
  }

  AmPm? _hourDiv12;
  AmPm? get hourDiv12 => _hourDiv12;

  /// Set the [hourDiv12] am/pm field to the given value.
  ///
  /// `false` indicates AM and `true` indicates PM.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set hourDiv12(AmPm value) {
    _throwIfInconsistent(hourDiv12, value);
    _hourDiv12 = value;
  }

  int? _hourMod12;
  int? get hourMod12 => _hourMod12;

  /// Set the [hourMod12] field, for the hour number in 12-hour clocks, to the
  /// given value.
  ///
  /// Value must be in the canonical range of 1 – 12. It will internally be
  /// stored as 0 – 11 (`value % 12`).
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is not in the range 1 – 12.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set hourMod12(int value) {
    if (value < 1 || value > 12) throw const ChronoParseException(.outOfRange);
    if (value == 12) value = 0;
    _throwIfInconsistent(hourMod12, value);
    _hourMod12 = value;
  }

  int? get hour {
    final hourDiv12 = this.hourDiv12;
    final hourMod12 = this.hourMod12;
    if (hourDiv12 == null || hourMod12 == null) return null;

    return hourMod12 +
        switch (hourDiv12) {
          .am => 0,
          .pm => 12,
        };
  }

  /// Set the [hourDiv12] and [hourMod12] fields to the given value for a
  /// 24-hour clock.
  ///
  /// # Exceptions
  ///
  /// May return `OUT_OF_RANGE` if [value] is not in the range 0 – 23. Currently
  /// only checks the value is not out of range for a `u32`.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if one of the fields was already set to a different value.
  set hour(int value) {
    final (hourDiv12, hourMod12) = switch (value) {
      >= 0 && <= 11 => (AmPm.am, value),
      >= 12 && <= 23 => (AmPm.pm, value - 12),
      _ => throw const ChronoParseException(.outOfRange),
    };
    _throwIfInconsistent(hourMod12, hourMod12);
    _hourMod12 = hourMod12;
    _throwIfInconsistent(hourDiv12, hourDiv12);
    _hourDiv12 = hourDiv12;
  }

  int? _minute;
  int? get minute => _minute;

  /// Set the [minute] field to the given value.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is not in the range 0 – 59.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set minute(int value) {
    if (value < 0 || value > 59) throw const ChronoParseException(.outOfRange);
    _throwIfInconsistent(minute, value);
    _minute = value;
  }

  int? _second;
  int? get second => _second;

  /// Set the [second] field to the given value.
  ///
  /// The value can be 60 in the case of a leap second.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is not in the range 0 – 60.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set second(int value) {
    if (value < 0 || value > 60) throw const ChronoParseException(.outOfRange);
    _throwIfInconsistent(second, value);
    _second = value;
  }

  int? _nanosecond;
  int? get nanosecond => _nanosecond;

  /// Set the [nanosecond] field to the given value.
  ///
  /// This is the number of nanoseconds since the whole second.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.outOfRange]
  /// if [value] is not in the range 0 – 999 999 999.
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set nanosecond(int value) {
    if (value < 0 || value > 999_999_999) {
      throw const ChronoParseException(.outOfRange);
    }
    _throwIfInconsistent(nanosecond, value);
    _nanosecond = value;
  }

  TimeDelta? _timestamp;
  TimeDelta? get timestamp => _timestamp;

  /// Set the [timestamp] field to the given value.
  ///
  /// A Unix timestamp is defined as the number of non-leap seconds since
  /// midnight UTC on January 1, 1970 (see [Instant.unixEpoch]).
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set timestamp(TimeDelta value) {
    _throwIfInconsistent(timestamp, value);
    _timestamp = value;
  }

  TimeDelta? _offset;
  TimeDelta? get offset => _offset;

  /// Set the [offset] field to the given value.
  ///
  /// The offset is in seconds from local time to UTC.
  ///
  /// # Exceptions
  ///
  /// Throws [ChronoParseException] with [ChronoParseExceptionKind.impossible]
  /// if this field was already set to a different value.
  set offset(TimeDelta value) {
    _throwIfInconsistent(offset, value);
    _offset = value;
  }

  /// Returns a parsed [Date] out of the given fields.
  ///
  /// This method is able to determine the date from given subset of fields:
  ///
  /// - Year, month, day
  /// - Year, day of the year (ordinal)
  /// - Year, week number counted from Sunday or Monday, day of the week
  /// - ISO week date
  ///
  /// Gregorian year and ISO week date year can have their century number
  /// (`*Div100`) omitted, the two-digit year is then used to guess the century
  /// number.
  ///
  /// It checks all given date fields are consistent with each other.
  ///
  /// # Exceptions
  ///
  /// This method throws [ChronoParseException] with the following kinds:
  /// - [ChronoParseExceptionKind.impossible] if any of the date fields conflict
  /// - [ChronoParseExceptionKind.notEnough] if there are not enough fields set
  ///   for a complete date
  /// - [ChronoParseExceptionKind.outOfRange]
  ///   - if any of the date fields are set to a value beyond their acceptable
  ///     range
  ///   - if the value would be outside the range of a [Date]
  ///   - if the date does not exist
  Date toDate() {
    Year? resolveYear(Year? y, int? div100, int? mod100) {
      return switch ((y, div100, mod100)) {
        // If there is no further information, simply return the given full
        // year. This is a common case, so let's avoid division here.
        (final y, null, null) => y,

        // If there is a full year *and* also quotient and/or modulo, check if
        // present quotient and/or modulo is consistent with the full year.
        // Since the presence of those fields means a positive full year,
        // we should filter a negative full year first.
        // TODO(JonasWanke): remove unnecessary range check?
        (final y?, final div100, null || (>= 0 && <= 99)) => () {
          if (y.number < 0) throw const ChronoParseException(.impossible);

          final div100_ = y.number ~/ 100;
          final mod100_ = y.number % 100;
          if ((div100 ?? div100_) != div100_ ||
              (mod100 ?? mod100_) != mod100_) {
            throw const ChronoParseException(.impossible);
          }

          return y;
        }(),

        // The full year is missing, but we have quotient and modulo.
        // Reconstruct the full year. Make sure that the result is always
        // positive.
        (null, final div100?, final mod100?) when 0 <= mod100 && mod100 <= 99 =>
          () {
            // TODO(JonasWanke): remove unnecessary range check?
            if (div100 < 0) throw const ChronoParseException(.impossible);

            final y = div100 * 100 + mod100;
            if (y < 0) throw const ChronoParseException(.outOfRange);
            return Year(y);
          }(),

        // We only have modulo. Try to interpret a modulo as a conventional
        // two-digit year.
        // TODO(JonasWanke): remove unnecessary range check?
        (null, null, final mod100?) when 0 <= mod100 && mod100 <= 99 => Year(
          mod100 + (mod100 < 70 ? 2000 : 1900),
        ),

        // TODO(JonasWanke): remove unnecessary range check?
        // Otherwise, it is an out-of-bound or insufficient condition.
        (null, final _?, null) => throw const ChronoParseException(.notEnough),
        (_, _, final _?) => throw const ChronoParseException(.outOfRange),
      };
    }

    final givenYear = resolveYear(year, yearDiv100, yearMod100);
    final givenIsoYear = resolveYear(isoYear, isoYearDiv100, isoYearMod100);

    // Verify the normal year-month-day date.
    bool verifyYmd(Date date) {
      final year = date.year;
      final (yearDiv100, yearMod100) = year.number >= 0
          ? (year.number ~/ 100, year.number % 100)
          : (null, null); // they should be empty to be consistent
      final month = date.month;
      final day = date.day;
      return (this.year ?? year) == year &&
          (this.yearDiv100 ?? yearDiv100) == yearDiv100 &&
          (this.yearMod100 ?? yearMod100) == yearMod100 &&
          (this.month ?? month) == month &&
          (this.day ?? day) == day;
    }

    // Verify the ISO week date.
    bool verifyIsoWeekDate(Date date) {
      final week = date.isoYearWeek;
      final isoYear = week.weekBasedYear;
      final isoWeek = week.week;
      final weekday = date.weekday;
      final (isoYearDiv100, isoYearMod100) = isoYear.number >= 0
          ? (isoYear.number ~/ 100, isoYear.number % 100)
          : (null, null); // they should be empty to be consistent
      return (this.isoYear ?? isoYear) == isoYear &&
          (this.isoYearDiv100 ?? isoYearDiv100) == isoYearDiv100 &&
          (this.isoYearMod100 ?? isoYearMod100) == isoYearMod100 &&
          (this.isoWeek ?? isoWeek) == isoWeek &&
          (this.weekday ?? weekday) == weekday;
    }

    // Verify the ordinal and other (non-ISO) week dates.
    bool verifyOrdinal(Date date) {
      final ordinal = date.dayOfYear;
      // TODO(JonasWanke): implement
      // final weekFromSun = date.weekFromSun;
      // final weekFromMon = date.weekFromMon;
      // return (this.ordinal ?? ordinal) == ordinal &&
      //     (this.weekFromSun ?? weekFromSun) == weekFromSun &&
      //     (this.weekFromMon ?? weekFromMon) == weekFromMon;
      return (this.ordinal ?? ordinal) == ordinal;
    }

    // Test several possibilities.
    //
    // Tries to construct a full [Date] as much as possible, then verifies that
    // it is consistent with other given fields.
    final (isVerified, parsedDate) = switch ((givenYear, givenIsoYear, this)) {
      (final year?, _, ChronoParsed(:final month?, :final day?)) => () {
        // year, month, day
        final Date date;
        try {
          date = Date.from(year, month, day);
          // ignore: avoid_catching_errors
        } on RangeError {
          throw const ChronoParseException(.outOfRange);
        }
        return (verifyIsoWeekDate(date) && verifyOrdinal(date), date);
      }(),
      (final year?, _, ChronoParsed(:final ordinal?)) => () {
        // year, day of the year
        final Date date;
        try {
          date = Date.fromYearAndOrdinal(year, ordinal);
          // ignore: avoid_catching_errors
        } on RangeError {
          throw const ChronoParseException(.outOfRange);
        }
        return (
          verifyYmd(date) && verifyIsoWeekDate(date) && verifyOrdinal(date),
          date,
        );
      }(),
      // TODO(JonasWanke): support weeks
      // (final year?, _, ChronoParsed( :final weekFromSun?, :final weekday?)) => (){
      //     // year, week (starting at 1st Sunday), day of the week
      //     let date = resolve_week_date(year, weekFromSun, weekday, Weekday::Sun)?;
      //     return (verifyYmd(date) && verifyIsoWeekDate(date) && verifyOrdinal(date), date);
      // }(),
      // (final year?, _, ChronoParsed( :final weekFromMon?, :final weekday?)) => (){
      //     // year, week (starting at 1st Monday), day of the week
      //     let date = resolve_week_date(year, weekFromMon, weekday, Weekday::Mon)?;
      //     return (verifyYmd(date) && verifyIsoWeekDate(date) && verifyOrdinal(date), date);
      // }(),
      (_, final isoYear?, ChronoParsed(:final isoWeek?, :final weekday?)) =>
        () {
          // ISO year, week, day of the week
          final Date date;
          try {
            date = Date.fromIsoYearAndWeekAndWeekday(isoYear, isoWeek, weekday);
            // ignore: avoid_catching_errors
          } on RangeError {
            throw const ChronoParseException(.outOfRange);
          }
          return (verifyYmd(date) && verifyOrdinal(date), date);
        }(),
      (_, _, _) => throw const ChronoParseException(.notEnough),
    };

    if (!isVerified) throw const ChronoParseException(.impossible);
    if (quarter case final quarter?) {
      // TODO(JonasWanke): quarter enum
      if (quarter != (parsedDate.month.index ~/ 3) + 1) {
        throw const ChronoParseException(.impossible);
      }
    }

    return parsedDate;
  }

  /// Returns a parsed [Time] out of the given fields.
  ///
  /// This method is able to determine the time from given subset of fields:
  ///
  /// - hour, minute (second and nanosecond assumed to be 0)
  /// - hour, minute, second (nanosecond assumed to be 0)
  /// - hour, minute, second, nanosecond
  ///
  /// It is able to handle leap seconds when the given second is 60.
  ///
  /// # Exceptions
  ///
  /// This method throws [ChronoParseException] with the following kinds:
  /// - [ChronoParseExceptionKind.outOfRange] if any of the time fields are set
  ///   to a value beyond their acceptable range.
  /// - [ChronoParseExceptionKind.notEnough] if an hour field is missing, if
  ///   AM/PM is missing in a 12-hour clock, if minutes are missing, or if
  ///   seconds are missing while the nanosecond field is present.
  Time toTime() {
    final hourDiv12 = this.hourDiv12;
    if (hourDiv12 == null) throw const ChronoParseException(.notEnough);

    final hourMod12 = this.hourMod12;
    if (hourMod12 == null) throw const ChronoParseException(.notEnough);
    final hour = switch (hourDiv12) {
      .am => hourMod12,
      .pm => hourMod12 + 12,
    };

    final minute = this.minute;
    if (minute == null) throw const ChronoParseException(.notEnough);

    // We allow omitting seconds or nanoseconds, but they should be in the
    // range.
    var (second, nano) = switch (this.second ?? 0) {
      // TODO(JonasWanke): support leap seconds
      60 => (59, 0),
      final value => (value, 0),
    };
    if (nanosecond case final nanosecond?) {
      if (this.second == null) throw const ChronoParseException(.notEnough);
      nano += nanosecond;
    }

    return Time.from(hour, minute, second, 0, 0, nano);
  }

  /// Returns a parsed [CDateTime] out of the given fields, except for the
  /// offset field.
  ///
  /// The offset is assumed to have a given value. It is not compared against
  /// the offset field set here, so it is allowed to be inconsistent.
  ///
  /// This method is able to determine the combined date and time from date and
  /// time fields or from a single timestamp field. It checks all fields are
  /// consistent with each other.
  ///
  /// # Exceptions
  ///
  /// This method throws [ChronoParseException] with the following kinds:
  /// - [ChronoParseExceptionKind.impossible]  if any of the date fields
  ///    conflict, or if a timestamp conflicts with any of the other fields.
  /// - [ChronoParseExceptionKind.notEnough] if there are not enough fields set
  ///   in `Parsed` for a complete datetime.
  /// - [ChronoParseExceptionKind.outOfRange]
  ///   - if any of the date or time fields are set to a value beyond their
  ///     acceptable range.
  ///   - if the value would be outside the range of a [CDateTime].
  ///   - if the date does not exist.
  CDateTime toDateTimeWithOffset(TimeDelta offset) {
    Date? date;
    (ChronoParseException, StackTrace)? dateException;
    try {
      date = toDate();
    } on ChronoParseException catch (e, st) {
      dateException = (e, st);
    }

    Time? time;
    (ChronoParseException, StackTrace)? timeException;
    try {
      time = toTime();
    } on ChronoParseException catch (e, st) {
      timeException = (e, st);
    }

    if (date != null && time != null) {
      final dateTime = date.at(time);
      // Verify the timestamp field if any.
      // the following is safe, `timestamp` is very limited in range
      final timestamp = dateTime.inUtc.durationSinceUnixEpoch - offset;
      if (this.timestamp case final givenTimestamp?) {
        // If `dateTime` represents a leap second, it might be off by one
        // second.
        if (givenTimestamp != timestamp &&
            !(dateTime.time.subSecondNanos >= 1_000_000_000 &&
                givenTimestamp == timestamp + TimeDelta(seconds: 1))) {
          throw const ChronoParseException(.impossible);
        }
      }

      return dateTime;
    } else if (timestamp case final timestamp?) {
      // If date and time is problematic already, there is no point in
      // proceeding. We at least try to give a correct error though.
      switch ((dateException, timeException)) {
        case ((ChronoParseException(kind: .outOfRange), _)?, _) ||
            (_, (ChronoParseException(kind: .outOfRange), _)?):
          throw const ChronoParseException(.outOfRange);
        case ((ChronoParseException(kind: .impossible), _)?, _) ||
            (_, (ChronoParseException(kind: .impossible), _)?):
          throw const ChronoParseException(.impossible);
        // Otherwise, one of them is insufficient.
      }

      // Reconstruct date and time fields from timestamp.
      final ts = timestamp + offset;
      var dateTime = Instant.fromDurationSinceUnixEpoch(ts).dateTimeInUtc;

      // Fill year, ordinal, hour, minute, and second fields from timestamp. If
      // existing fields are consistent, this will allow the full date/time
      // reconstruction.
      final parsed = clone();
      if (parsed.second == 60) {
        // `dateTime.time.second` cannot be 60, so this is the only case for a
        // leap second.
        switch (dateTime.time.second) {
          // It's okay, just do not try to overwrite the existing field.
          case 59:
            break;
          // [dateTime] is known to be off by one second.
          case 0:
            dateTime -= TimeDelta(seconds: 1);
          // Otherwise, it is impossible.
          default:
            throw const ChronoParseException(.impossible);
        }
        // ...and we have the correct candidates for other fields.
      } else {
        parsed.second = dateTime.time.second;
      }
      parsed.year = dateTime.date.year;
      parsed.ordinal = dateTime.date.dayOfYear; // more efficient than ymd
      parsed.hour = dateTime.time.hour;
      parsed.minute = dateTime.time.minute;

      // Validate other fields (e.g., week) and return.
      return parsed.toDate().at(parsed.toTime());
    } else {
      // Reproduce the previous error(s).
      final error = dateException ?? timeException;
      Error.throwWithStackTrace(error!.$1, error.$2);
    }
  }

  /// Returns a parsed fixed time zone offset out of given fields.
  ///
  /// # Exceptions
  ///
  /// This method throws a [ChronoParseException] with
  /// [ChronoParseExceptionKind.notEnough] if the offset field is not set.
  FixedOffset toFixedOffset() {
    return FixedOffset.east(
      offset ?? (throw const ChronoParseException(.notEnough)),
    );
  }

  /// Returns a parsed [ZonedDateTime] out of the given fields.
  ///
  /// This method is able to determine the combined date and time from date,
  /// time, and offset fields, and/or from a single timestamp field. It checks
  /// all fields are consistent with each other.
  ///
  /// # Exceptions
  ///
  /// This method throws a [ChronoParseException] with the following kinds:
  /// - [ChronoParseExceptionKind.impossible] if any of the date fields
  ///   conflict, or if a timestamp conflicts with any of the other fields.
  /// - [ChronoParseExceptionKind.notEnough] if there are not enough fields set
  ///   for a complete datetime including offset from UTC.
  /// - [ChronoParseExceptionKind.outOfRange]
  ///   - if any of the fields are set to a value beyond their acceptable range.
  ///   - if the value would be outside the range of a [CDateTime] or
  ///     [FixedOffset].
  ///   - if the date does not exist.
  ZonedDateTime<FixedOffset> toZonedDateTime() {
    // If there is no explicit offset, consider a timestamp value as indication
    // of a UTC value.
    final offset = switch ((this.offset, timestamp)) {
      (final offset?, _) => offset,
      (null, final _?) => TimeDelta(), // UNIX timestamp may assume 0 offset
      (null, null) => throw const ChronoParseException(.notEnough),
    };
    final dateTime = toDateTimeWithOffset(offset);

    return switch (FixedOffset.east(offset).fromLocalDateTime(dateTime)) {
      MappedLocalTime_None() => throw const ChronoParseException(.impossible),
      MappedLocalTime_Single(:final value) => value,
      MappedLocalTime_Ambiguous() => throw const ChronoParseException(
        .notEnough,
      ),
    };
  }

  /// Returns a parsed timezone-aware date and time out of the given fields,
  /// with an additional [TimeZone] used to interpret and validate the local
  /// date.
  ///
  /// This method is able to determine the combined date and time from date and
  /// time, and/or from a single timestamp field. It checks that all fields are
  /// consistent with each other.
  ///
  /// If the parsed fields include an UTC offset, it also has to be consistent
  /// with the offset in the provided [tz] time zone for that datetime.
  ///
  /// # Exceptions
  ///
  /// This method throws a [ChronoParseException] with the following kinds:
  /// - [ChronoParseExceptionKind.impossible]
  ///   - if any of the date fields conflict, if a timestamp conflicts with any
  ///     of the other fields, or if the offset field is set but differs from
  ///     the offset at that time in the [tz] time zone.
  ///   - if the local datetime does not exists in the provided time zone
  ///     (because it falls in a transition due to, for example, DST).
  /// - [ChronoParseExceptionKind.notEnough] if there are not enough fields set
  ///   for a complete datetime, or if the local time in the provided time zone
  ///   is ambiguous (because it falls in a transition due to, for example, DST)
  ///   while there is no offset field or timestamp field set.
  /// - [ChronoParseExceptionKind.outOfRange]
  ///   - if the value would be outside the range of a [CDateTime] or
  ///     [FixedOffset].
  ///   - if the date does not exist.
  ZonedDateTime<Tz> toZonedDateTimeWithTimeZone<Tz extends TimeZone<Tz>>(
    Tz tz,
  ) {
    // If we have `timestamp` specified, guess an offset from that.
    var guessedOffset = TimeDelta();
    if (timestamp case final timestamp?) {
      // Make a [CDateTime] from the given timestamp and (if any) nanosecond. An
      // empty `nanosecond` is always equal to zero, so missing nanosecond is
      // fine.
      final nanosecond = this.nanosecond ?? 0;
      final dt = Instant.fromDurationSinceUnixEpoch(
        timestamp + TimeDelta(nanos: nanosecond),
      ).dateTimeInUtc;
      guessedOffset = tz.offsetFromUtcDateTime(dt).fix().localMinusUtc;
    }

    /// Checks if the given [ZonedDateTime] has a consistent [Offset] with given
    /// [offset].
    bool checkOffset(ZonedDateTime<Tz> dt) {
      if (offset case final offset?) {
        return dt.offset.fix().localMinusUtc == offset;
      } else {
        return true;
      }
    }

    // [guessedOffset] should be correct when [timestamp] is given. It will be 0
    // otherwise, but this is fine as the algorithm ignores offset for that
    // case.
    final dateTime = toDateTimeWithOffset(guessedOffset);
    return switch (tz.fromLocalDateTime(dateTime)) {
      MappedLocalTime_None() => throw const ChronoParseException(.impossible),
      MappedLocalTime_Single(:final value) =>
        checkOffset(value)
            ? value
            : throw const ChronoParseException(.impossible),
      MappedLocalTime_Ambiguous(:final earliest, :final latest) => () {
        // Try to disambiguate two possible local dates by offset.
        final earliestIsOk = checkOffset(earliest);
        final latestIsOk = checkOffset(latest);
        switch ((earliestIsOk, latestIsOk)) {
          case (false, false):
            throw const ChronoParseException(.impossible);
          case (false, true):
            return latest;
          case (true, false):
            return earliest;
          case (true, true):
            throw const ChronoParseException(.notEnough);
        }
      }(),
    };
  }

  /// Checks if `old` is either empty or has the same value as `new` (i.e.
  /// "consistent"), and throws [ChronoParseException] with
  /// [ChronoParseExceptionKind.impossible] if not.
  void _throwIfInconsistent<T>(T? oldValue, T newValue) {
    if (oldValue != null && oldValue != newValue) {
      throw const ChronoParseException(.impossible);
    }
  }

  ChronoParsed clone() {
    final copy = ChronoParsed();
    copy._year = _year;
    copy._yearDiv100 = _yearDiv100;
    copy._yearMod100 = _yearMod100;
    copy._isoYear = _isoYear;
    copy._isoYearDiv100 = _isoYearDiv100;
    copy._isoYearMod100 = _isoYearMod100;
    copy._quarter = _quarter;
    copy._month = _month;
    copy._weekFromSun = _weekFromSun;
    copy._weekFromMon = _weekFromMon;
    copy._isoWeek = _isoWeek;
    copy._weekday = _weekday;
    copy._ordinal = _ordinal;
    copy._day = _day;
    copy._hourDiv12 = _hourDiv12;
    copy._hourMod12 = _hourMod12;
    copy._minute = _minute;
    copy._second = _second;
    copy._nanosecond = _nanosecond;
    copy._timestamp = _timestamp;
    copy._offset = _offset;
    return copy;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChronoParsed &&
            _year == other._year &&
            _yearDiv100 == other._yearDiv100 &&
            _yearMod100 == other._yearMod100 &&
            _isoYear == other._isoYear &&
            _isoYearDiv100 == other._isoYearDiv100 &&
            _isoYearMod100 == other._isoYearMod100 &&
            _quarter == other._quarter &&
            _month == other._month &&
            _weekFromSun == other._weekFromSun &&
            _weekFromMon == other._weekFromMon &&
            _isoWeek == other._isoWeek &&
            _weekday == other._weekday &&
            _ordinal == other._ordinal &&
            _day == other._day &&
            _hourDiv12 == other._hourDiv12 &&
            _hourMod12 == other._hourMod12 &&
            _minute == other._minute &&
            _second == other._second &&
            _nanosecond == other._nanosecond &&
            _timestamp == other._timestamp &&
            _offset == other._offset);
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => Object.hashAll([
    _year,
    _yearDiv100,
    _yearMod100,
    _isoYear,
    _isoYearDiv100,
    _isoYearMod100,
    _quarter,
    _month,
    _weekFromSun,
    _weekFromMon,
    _isoWeek,
    _weekday,
    _ordinal,
    _day,
    _hourDiv12,
    _hourMod12,
    _minute,
    _second,
    _nanosecond,
    _timestamp,
    _offset,
  ]);

  @override
  String toString() {
    final buffer = StringBuffer('ChronoParsed(');
    var isFirst = true;
    void maybeAdd(String name, Object? value) {
      if (value == null) return;
      if (!isFirst) buffer.write(', ');
      buffer.write('$name: $value');
      isFirst = false;
    }

    maybeAdd('_year', _year);
    maybeAdd('_yearDiv100', _yearDiv100);
    maybeAdd('_yearMod100', _yearMod100);
    maybeAdd('_isoYear', _isoYear);
    maybeAdd('_isoYearDiv100', _isoYearDiv100);
    maybeAdd('_isoYearMod100', _isoYearMod100);
    maybeAdd('_quarter', _quarter);
    maybeAdd('_month', _month);
    maybeAdd('_weekFromSun', _weekFromSun);
    maybeAdd('_weekFromMon', _weekFromMon);
    maybeAdd('_isoWeek', _isoWeek);
    maybeAdd('_weekday', _weekday);
    maybeAdd('_ordinal', _ordinal);
    maybeAdd('_day', _day);
    maybeAdd('_hourDiv12', _hourDiv12);
    maybeAdd('_hourMod12', _hourMod12);
    maybeAdd('_minute', _minute);
    maybeAdd('_second', _second);
    maybeAdd('_nanosecond', _nanosecond);
    maybeAdd('_timestamp', _timestamp);
    maybeAdd('_offset', _offset);
    buffer.write(')');
    return buffer.toString();
  }
}
