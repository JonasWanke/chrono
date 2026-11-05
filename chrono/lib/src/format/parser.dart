import '../../chrono.dart';

// Based on Rust Chrono's parser: https://github.com/chronotope/chrono/blob/3ffcd1b107fd3085bc184a1f5f7445b97a0d655f/src/format/parse.rs
class ChronoParser._(var String _string) {
  final _parsed = ChronoParsed();

  /// Tries to parse given [string] with given formatting [items].
  ///
  /// Returns [ChronoParsed] when the entire string has been parsed. There
  /// should be no trailing string after parsing; use a stray
  /// [ChronoFormatItemSpace] to trim whitespaces.
  ///
  /// This particular date and time parser is:
  ///
  /// - Greedy. It will consume the longest possible prefix.
  ///   For example, `April` is always consumed entirely when the long month
  ///   name is requested; it equally accepts `Apr`, but prefers the longer
  ///   prefix in this case.
  /// - Padding-agnostic (for numeric items).
  ///   The [ChronoPadding] field is completely ignored, so one can prepend any
  ///   number of whitespace then any number of zeroes before numbers.
  /// - (Still) obeying the intrinsic parsing width. This allows, for example,
  ///   parsing `HHMMSS`.
  static ChronoParsed parse(String string, List<ChronoFormatItem> items) {
    final (:parsed, :rest) = parseAndRest(string, items);
    if (rest.isNotEmpty) throw const ChronoParseException(.tooLong);
    return parsed;
  }

  /// Tries to parse given string into `parsed` with the given formatting items
  /// and also returns the remaining String.
  ///
  /// This particular date and time parser is:
  ///
  /// - Greedy. It will consume the longest possible prefix. For example,
  ///   `April` is always consumed entirely when the long month name is
  ///   requested; it equally accepts `Apr`, but prefers the longer prefix in
  ///   this case.
  /// - Padding-agnostic (for numeric items). The [ChronoPadding] field is
  ///   completely ignored, so one can prepend any number of zeroes before
  ///   numbers.
  /// - (Still) obeying the intrinsic parsing width. This allows, for example,
  ///   parsing `HHMMSS`.
  static ({ChronoParsed parsed, String rest}) parseAndRest(
    String string,
    List<ChronoFormatItem> items,
  ) {
    final parser = ChronoParser._(string);
    parser._parseAndRemainder(items);
    return (parsed: parser._parsed, rest: parser._string);
  }

  /// Parses [string] as a strict RFC 3339 date and time, e.g.,
  /// “2015-01-20T17:35:20.001-08:00”.
  ///
  /// This is the grammar of Rust's `DateTime::parse_from_rfc3339`:
  ///
  /// - The date and time are separated by `T`, `t`, or a space.
  /// - The offset is `Z`/`z` or a signed `hh:mm` (with a colon) from `-23:59`
  ///   to `+23:59`. The ASCII hyphen-minus and U+2212 are both accepted as the
  ///   minus sign.
  /// - Any number of fractional-second digits is accepted; digits beyond the
  ///   ninth are ignored.
  ///
  /// Throws a [ChronoParseException] if [string] doesn't match.
  static ChronoParsed parseRfc3339(String string) {
    final parser = ChronoParser._(string);
    parser._parseRfc3339();
    if (parser._string.isNotEmpty) throw const ChronoParseException(.tooLong);
    return parser._parsed;
  }

  /// Parses [string] as an RFC 2822 date and time, e.g.,
  /// “Tue, 20 Jan 2015 17:35:20 -0800”.
  ///
  /// This is the grammar of Rust's `DateTime::parse_from_rfc2822`:
  ///
  /// - The weekday is optional, but must match the date if present.
  /// - Whitespace between tokens is flexible, and trailing parenthesized
  ///   comments (which may be nested and contain backslash escapes) are
  ///   ignored.
  /// - The year may have two digits (`00` to `49` mean 20xx, `50` to `99` mean
  ///   19xx), three digits (add 1900), or four or more digits.
  /// - The seconds are optional.
  /// - The zone is a signed `hhmm` offset or one of the names `GMT`, `UT`,
  ///   `EST`, `EDT`, `CST`, `CDT`, `MST`, `MDT`, `PST`, `PDT` (in any case).
  ///   The military single-letter zones, except `J`, are treated as `+0000`.
  ///   `Z` is accepted as a military zone, but must be separated from the time
  ///   by whitespace.
  ///
  /// Throws a [ChronoParseException] if [string] doesn't match.
  static ChronoParsed parseRfc2822(String string) {
    final parser = ChronoParser._(string);
    parser._parseRfc2822();
    if (parser._string.isNotEmpty) throw const ChronoParseException(.tooLong);
    return parser._parsed;
  }

  void _parseAndRemainder(List<ChronoFormatItem> items) {
    for (final item in items) {
      switch (item) {
        case ChronoFormatItemLiteral(:final text):
          if (_string.length < text.length) {
            throw const ChronoParseException(.tooShort);
          } else if (!_string.startsWith(text)) {
            throw const ChronoParseException(.invalid);
          }
          _string = _string.substring(text.length);

        case ChronoFormatItemSpace():
          _string = _string.trimLeft();

        case ChronoFormatItemNumeric():
          final (width, signed, void Function(int) set) = switch (item) {
            ChronoFormatYear(format: .full) => (
              4,
              true,
              (it) => _parsed.year = Year(it),
            ),
            ChronoFormatYear(format: .div100) => (
              2,
              false,
              (it) => _parsed.yearDiv100 = it,
            ),
            ChronoFormatYear(format: .mod100) => (
              2,
              false,
              (it) => _parsed.yearMod100 = it,
            ),
            ChronoFormatIsoYear(format: .full) => (
              4,
              true,
              (it) => _parsed.isoYear = Year(it),
            ),
            ChronoFormatIsoYear(format: .div100) => (
              2,
              false,
              (it) => _parsed.isoYearDiv100 = it,
            ),
            ChronoFormatIsoYear(format: .mod100) => (
              2,
              false,
              (it) => _parsed.isoYearMod100 = it,
            ),
            ChronoFormatQuarter() => (
              1,
              false,
              (it) => _parsed.quarter =
                  Quarter.fromNumberOrNull(it) ??
                  (throw const ChronoParseException(.outOfRange)),
            ),
            ChronoFormatMonth() => (
              2,
              false,
              (it) => _parsed.month =
                  Month.fromNumberOrNull(it) ??
                  (throw const ChronoParseException(.outOfRange)),
            ),
            ChronoFormatDay() => (2, false, (it) => _parsed.day = it),
            ChronoFormatWeekFromSun() => (
              2,
              false,
              (it) => _parsed.weekFromSun = it,
            ),
            ChronoFormatWeekFromMon() => (
              2,
              false,
              (it) => _parsed.weekFromMon = it,
            ),
            ChronoFormatIsoWeek() => (2, false, (it) => _parsed.isoWeek = it),
            ChronoFormatNumDaysFromSun() => (
              1,
              false,
              (it) => _parsed.weekday = it >= Weekday.values.length
                  ? throw const ChronoParseException(.outOfRange)
                  : Weekday.sunday + Days(it),
            ),
            ChronoFormatWeekday() => (
              1,
              false,
              (it) => _parsed.weekday =
                  Weekday.fromNumberOrNull(it) ??
                  (throw const ChronoParseException(.outOfRange)),
            ),
            ChronoFormatOrdinal() => (3, false, (it) => _parsed.ordinal = it),
            ChronoFormatHour() => (2, false, (it) => _parsed.hour = it),
            ChronoFormatHour12() => (2, false, (it) => _parsed.hourMod12 = it),
            ChronoFormatMinute() => (2, false, (it) => _parsed.minute = it),
            ChronoFormatSecond() => (2, false, (it) => _parsed.second = it),
            ChronoFormatNanosecond() => (
              9,
              false,
              (it) => _parsed.nanosecond = it,
            ),
            ChronoFormatTimestamp() => (
              null,
              false,
              (it) => _parsed.timestamp = TimeDelta(seconds: it),
            ),
          };
          _string = _string.trimLeft();
          final int value;
          if (signed) {
            if (_string.startsWith('-')) {
              _string = _string.substring(1);
              value = -_scanNumber(1, null);
            } else if (_string.startsWith('+')) {
              _string = _string.substring(1);
              value = _scanNumber(1, null);
            } else {
              // If there is no explicit sign, we respect the original [width].
              value = _scanNumber(1, width);
            }
          } else {
            value = _scanNumber(1, width);
          }
          set(value);

        case ChronoFormatItemFixed():
          switch (item) {
            case ChronoFormatMonthName(:final length):
              _parsed.month = switch (length) {
                .short => _scanShortMonth(),
                .full => _scanShortOrFullMonth(),
              };

            case ChronoFormatWeekdayName(:final length):
              _parsed.weekday = switch (length) {
                .short => _scanShortWeekday(),
                .full => _scanShortOrFullWeekday(),
              };

            case ChronoFormatAmPm():
              if (_string.length < 2) {
                throw const ChronoParseException(.tooShort);
              }
              _parsed.hourDiv12 = switch (_string
                  .substring(0, 2)
                  .toLowerCase()) {
                'am' => .am,
                'pm' => .pm,
                _ => throw const ChronoParseException(.invalid),
              };
              _string = _string.substring(2);

            case ChronoFormatSubsecond(:final accuracy):
              if (!_string.startsWith('.')) break;
              _string = _string.substring(1);

              _parsed.nanosecond = switch (accuracy) {
                .variable => _scanNanosecond(),
                .millis => _scanNanosecondFixed(3),
                .micros => _scanNanosecondFixed(6),
                .nanos => _scanNanosecondFixed(9),
              };

            case ChronoFormatTimezoneName():
              final match = RegExp(r'\S+').matchAsPrefix(_string);
              if (match != null) _string = _string.substring(match.end);

            case ChronoFormatTimezoneOffset(:final allowZulu):
              _string = _string.trimLeft();
              _parsed.offset = _scanTimezoneOffset(
                consumeColon: _scanColonOrSpace,
                allowZulu: allowZulu,
                allowMissingMinutes: false,
                allowTzMinusSign: true,
              );
          }

        case ChronoFormatItemError():
          throw const ChronoParseException(.badFormat);
      }
    }
  }

  void _parseRfc3339() {
    // date-time = full-date ("T" / "t" / " ") full-time, see RFC 3339 section
    // 5.6. Unlike RFC 2822, the offset range is -23:59 to +23:59.
    _parsed.year = Year(_scanNumber(4, 4));
    _scanChar('-');
    _parsed.month =
        Month.fromNumberOrNull(_scanNumber(2, 2)) ??
        (throw const ChronoParseException(.outOfRange));
    _scanChar('-');
    _parsed.day = _scanNumber(2, 2);

    switch (_string.isEmpty ? null : _string[0]) {
      case 'T' || 't' || ' ':
        _string = _string.substring(1);
      case _?:
        throw const ChronoParseException(.invalid);
      case null:
        throw const ChronoParseException(.tooShort);
    }

    _parsed.hour = _scanNumber(2, 2);
    _scanChar(':');
    _parsed.minute = _scanNumber(2, 2);
    _scanChar(':');
    _parsed.second = _scanNumber(2, 2);
    if (_string.startsWith('.')) {
      _string = _string.substring(1);
      _parsed.nanosecond = _scanNanosecond();
    }

    final offset = _scanTimezoneOffset(
      consumeColon: () => _scanChar(':'),
      allowZulu: true,
      allowMissingMinutes: false,
      allowTzMinusSign: true,
    );
    if (offset.wholeSeconds.abs() > 86399) {
      throw const ChronoParseException(.outOfRange);
    }
    _parsed.offset = offset;
  }

  void _parseRfc2822() {
    // date-time   = [ day-of-week "," ] date 1*S time *S *comment
    // date        = day month year
    // time        = time-of-day 1*S zone
    // time-of-day = hour ":" minute [ ":" second ]
    //
    // See RFC 2822 sections 3.3 and 4.3. Folding whitespace is accepted as any
    // sequence of Unicode whitespace (denoted `S`), and comments only after the
    // zone.
    _string = _string.trimLeft();

    // The weekday is optional, so a failure to scan one is not an error.
    Weekday? weekday;
    try {
      weekday = _scanShortWeekday();
    } on ChronoParseException {
      // Not a weekday; `_string` is unchanged.
    }
    if (weekday != null) {
      if (!_string.startsWith(',')) throw const ChronoParseException(.invalid);

      _string = _string.substring(1);
      _parsed.weekday = weekday;
    }

    _string = _string.trimLeft();
    _parsed.day = _scanNumber(1, 2);
    _scanSpace();
    _parsed.month = _scanShortMonth();
    _scanSpace();

    // Two- and three-digit years are shifted, four-digit years are not.
    final lengthBeforeYear = _string.length;
    var year = _scanNumber(2, null);
    switch ((lengthBeforeYear - _string.length, year)) {
      case (2, < 50):
        year += 2000;
      case (2, _):
        year += 1900;
      case (3, _):
        year += 1900;
    }
    _parsed.year = Year(year);

    _scanSpace();
    _parsed.hour = _scanNumber(2, 2);
    _string = _string.trimLeft();
    _scanChar(':');
    _string = _string.trimLeft();
    _parsed.minute = _scanNumber(2, 2);
    final beforeSeconds = _string.trimLeft();
    if (beforeSeconds.startsWith(':')) {
      _string = beforeSeconds.substring(1).trimLeft();
      _parsed.second = _scanNumber(2, 2);
    }

    _scanSpace();
    _parsed.offset = _scanTimezoneOffset2822();

    while (_scanComment2822()) {}
  }

  /// Consumes exactly the character [expected].
  void _scanChar(String expected) {
    if (_string.isEmpty) throw const ChronoParseException(.tooShort);
    if (_string[0] != expected) throw const ChronoParseException(.invalid);

    _string = _string.substring(1);
  }

  /// Consumes one mandatory whitespace character and all whitespace after it.
  void _scanSpace() {
    if (_string.isEmpty) throw const ChronoParseException(.tooShort);
    if (_string.trimLeft().length == _string.length) {
      throw const ChronoParseException(.invalid);
    }

    _string = _string.trimLeft();
  }

  /// Parses an RFC 2822 zone: either a legacy name or a signed `hhmm` offset.
  TimeDelta _scanTimezoneOffset2822() {
    final name = RegExp('^[A-Za-z]+').stringMatch(_string);
    if (name == null) {
      return _scanTimezoneOffset(
        consumeColon: () {},
        allowZulu: false,
        allowMissingMinutes: false,
        allowTzMinusSign: false,
      );
    }

    // RFC 2822 requires a few North American zones. The military single-letter
    // zones are treated as `+0000` (“-0000” in the RFC), except for `J`.
    final lowercase = name.toLowerCase();
    final offsetHours = switch (lowercase) {
      'gmt' || 'ut' || 'z' => 0,
      'edt' => -4,
      'est' || 'cdt' => -5,
      'cst' || 'mdt' => -6,
      'mst' || 'pdt' => -7,
      'pst' => -8,
      _ when lowercase.length == 1 && lowercase != 'j' => 0,
      _ => throw const ChronoParseException(.invalid),
    };
    _string = _string.substring(name.length);
    return TimeDelta(hours: offsetHours);
  }

  /// Consumes a comment `( … )` (which may contain nested comments and
  /// backslash escapes) and all whitespace before it.
  ///
  /// Returns whether a comment was consumed. If not, nothing is consumed.
  bool _scanComment2822() {
    final string = _string.trimLeft();
    if (!string.startsWith('(')) return false;

    var depth = 0;
    var isEscaped = false;
    for (var i = 0; i < string.length; i++) {
      final character = string[i];
      if (isEscaped) {
        isEscaped = false;
      } else if (character == r'\') {
        isEscaped = true;
      } else if (character == '(') {
        depth++;
      } else if (character == ')') {
        depth--;
        if (depth == 0) {
          _string = string.substring(i + 1);
          return true;
        }
      }
    }
    // The comment isn't closed.
    return false;
  }

  /// Tries to parse the non-negative number from [minDigits] to [maxDigits].
  ///
  /// The absence of digits at all is an unconditional error.
  int _scanNumber(int minDigits, int? maxDigits) {
    if (_string.length < minDigits) throw const ChronoParseException(.tooShort);

    var codeUnits = _string.codeUnits.indexed;
    if (maxDigits != null) codeUnits = codeUnits.take(maxDigits);

    var result = 0;
    var digits = 0;
    for (final (index, codeUnit) in codeUnits) {
      if (codeUnit < 0x30 || codeUnit > 0x39) {
        if (index < minDigits) throw const ChronoParseException(.invalid);
        break;
      }

      result = result * 10 + (codeUnit - 0x30);
      digits++;
    }

    _string = _string.substring(digits);
    return result;
  }

  /// Tries to parse the month with the first three ASCII letters.
  Month _scanShortMonth() {
    if (_string.length < 3) throw const ChronoParseException(.tooShort);

    // ignore: omit_local_variable_types
    final Month month = switch (_string.substring(0, 3).toLowerCase()) {
      'jan' => .january,
      'feb' => .february,
      'mar' => .march,
      'apr' => .april,
      'may' => .may,
      'jun' => .june,
      'jul' => .july,
      'aug' => .august,
      'sep' => .september,
      'oct' => .october,
      'nov' => .november,
      'dec' => .december,
      _ => throw const ChronoParseException(.invalid),
    };
    _string = _string.substring(3);
    return month;
  }

  Month _scanShortOrFullMonth() {
    // Lowercased month names, minus first three chars.
    const suffixes = [
      'uary',
      'ruary',
      'ch',
      'il',
      '',
      'e',
      'y',
      'ust',
      'tember',
      'ober',
      'ember',
      'ember',
    ];

    final month = _scanShortMonth();

    // Tries to consume the suffix if possible.
    final suffix = suffixes[month.index];
    if (_string.length >= suffix.length &&
        _string.substring(0, suffix.length).toLowerCase() == suffix) {
      _string = _string.substring(suffix.length);
    }
    return month;
  }

  /// Tries to parse the weekday with the first three ASCII letters.
  Weekday _scanShortWeekday() {
    if (_string.length < 3) throw const ChronoParseException(.tooShort);

    // ignore: omit_local_variable_types
    final Weekday weekday = switch (_string.substring(0, 3).toLowerCase()) {
      'mon' => .monday,
      'tue' => .tuesday,
      'wed' => .wednesday,
      'thu' => .thursday,
      'fri' => .friday,
      'sat' => .saturday,
      'sun' => .sunday,
      _ => throw const ChronoParseException(.invalid),
    };
    _string = _string.substring(3);
    return weekday;
  }

  Weekday _scanShortOrFullWeekday() {
    // Lowercased weekday names, minus first three chars.
    const suffixes = ['day', 'sday', 'nesday', 'rsday', 'day', 'urday', 'day'];

    final weekday = _scanShortWeekday();

    // Tries to consume the suffix if possible.
    final suffix = suffixes[weekday.index];
    if (_string.length >= suffix.length &&
        _string.substring(0, suffix.length).toLowerCase() == suffix) {
      _string = _string.substring(suffix.length);
    }
    return weekday;
  }

  static const _nanosecondScale = [
    0,
    100_000_000,
    10_000_000,
    1_000_000,
    100_000,
    10_000,
    1_000,
    100,
    10,
    1,
  ];

  /// Tries to consume at least one digit as a fractional second.
  ///
  /// Returns the number of whole nanoseconds (0 – 999 999 999).
  int _scanNanosecond() {
    // Record the number of digits consumed for later scaling.
    final originalLength = _string.length;
    var value = _scanNumber(1, 9);
    final consumed = originalLength - _string.length;

    value *= _nanosecondScale[consumed];

    // If there are more than 9 digits, skip next digits.
    _string = _string.replaceFirst(RegExp(r'^\d+'), '');

    return value;
  }

  /// Tries to consume a fixed number of digits as a fractional second.
  ///
  /// Returns the number of whole nanoseconds (0 – 999 999 999).
  int _scanNanosecondFixed(int digits) =>
      _scanNumber(digits, digits) * _nanosecondScale[digits];

  /// Parse a timezone and return the offset in seconds.
  ///
  /// The [consumeColon] function is used to parse a mandatory or optional `:`
  /// separator between hours offset and minutes offset.
  ///
  /// The [allowMissingMinutes] flag allows the timezone minutes offset to be
  /// missing.
  ///
  /// The [allowTzMinusSign] flag allows the timezone offset negative character
  /// to also be `−` MINUS SIGN (U+2212) in addition to the typical
  /// ASCII-compatible `-` HYPHEN-MINUS (U+2D). This is part of
  /// [RFC 3339 & ISO 8601](https://en.wikipedia.org/w/index.php?title=ISO_8601&oldid=1114309368#Time_offsets_from_UTC)
  TimeDelta _scanTimezoneOffset({
    required void Function() consumeColon,
    required bool allowZulu,
    required bool allowMissingMinutes,
    required bool allowTzMinusSign,
  }) {
    if (allowZulu &&
        _string.isNotEmpty &&
        (_string[0] == 'Z' || _string[0] == 'z')) {
      _string = _string.substring(1);
      return TimeDelta();
    }

    (int, int) digits() {
      if (_string.codeUnits.length < 2) {
        throw const ChronoParseException(.tooShort);
      }

      final result = (_string.codeUnits[0] - 0x30, _string.codeUnits[1] - 0x30);
      _string = _string.substring(2);
      return result;
    }

    // const fn digits(s: &str) -> ParseResult<(u8, u8)> {
    //     let b = s.as_bytes();
    //     if b.len() < 2 { Err(TOO_SHORT) } else { Ok((b[0], b[1])) }
    // }
    final isNegative = switch (_string.isNotEmpty ? _string[0] : null) {
      '+' => () {
        // PLUS SIGN (U+2B)
        _string = _string.substring(1);
        return false;
      }(),
      '-' => () {
        // HYPHEN-MINUS (U+2D)
        _string = _string.substring(1);
        return true;
      }(),
      '−' => () {
        // MINUS SIGN (U+2212)
        if (!allowTzMinusSign) {
          throw const ChronoParseException(.invalid);
        }
        _string = _string.substring(1);
        return true;
      }(),
      final _? => throw const ChronoParseException(.invalid),
      null => throw const ChronoParseException(.tooShort),
    };

    // hours (00 – 99)
    final hours = switch (digits()) {
      (final h1, final h2) when h1 >= 0 && h1 <= 9 && h2 >= 0 && h2 <= 9 =>
        h1 * 10 + h2,
      _ => throw const ChronoParseException(.invalid),
    };

    // colons (and possibly other separators)
    consumeColon();

    // minutes (00 – 59)
    // If the next two items are digits, then we have to add minutes.
    int minutes;
    try {
      minutes = switch (digits()) {
        (final m1, final m2) when m1 >= 0 && m1 <= 5 && m2 >= 0 && m2 <= 9 =>
          m1 * 10 + m2,
        (final m1, final m2) when m1 >= 6 && m1 <= 9 && m2 >= 0 && m2 <= 9 =>
          throw const ChronoParseException(.outOfRange),
        _ => throw const ChronoParseException(.invalid),
      };
    } on ChronoParseException {
      if (allowMissingMinutes) {
        minutes = 0;
      } else {
        rethrow;
      }
    }

    var result = TimeDelta(hours: hours, minutes: minutes);
    if (isNegative) result = -result;
    return result;
  }

  /// Consumes any number (including zero) of colon or spaces.
  void _scanColonOrSpace() {
    final match = RegExp(r'[:\s]+').matchAsPrefix(_string);
    if (match != null) _string = _string.substring(match.end);
  }
}

class const ChronoParseException(final ChronoParseExceptionKind kind)
    implements Exception {
  @override
  String toString() => 'ChronoParseException: $kind';
}

/// The category of parse error.
enum ChronoParseExceptionKind {
  /// Given field is out of permitted range.
  outOfRange,

  /// There is no possible date and time value with given set of fields.
  ///
  /// This does not include the out-of-range conditions, which are trivially
  /// invalid. It includes the case that there are one or more fields that are
  /// inconsistent with each other.
  impossible,

  /// Given set of fields is not enough to make a requested date and time
  /// value.
  ///
  /// Note that there *may* be a case that given fields constrain the possible
  /// values so much that there is a unique possible value. Chrono only tries
  /// to be correct for most useful sets of fields, however, as such
  /// constraint solving can be expensive.
  notEnough,

  /// The input string has some invalid character sequence for given
  /// formatting items.
  invalid,

  /// The input string has ended prematurely.
  tooShort,

  /// All formatting items have been read but there is a remaining input.
  tooLong,

  /// There was an error on the formatting string, or there were non-supported
  /// formatting items.
  badFormat;

  @override
  String toString() => switch (this) {
    .outOfRange => 'input is out of range',
    .impossible => 'no possible date and time matching input',
    .notEnough => 'input is not enough for unique date and time',
    .invalid => 'input contains invalid characters',
    .tooShort => 'premature end of input',
    .tooLong => 'trailing input',
    .badFormat => 'bad or unsupported format string',
  };
}
