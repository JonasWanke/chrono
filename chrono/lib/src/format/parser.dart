import '../../chrono.dart';

// Based on Rust Chrono's parser: https://github.com/chronotope/chrono/blob/3ffcd1b107fd3085bc184a1f5f7445b97a0d655f/src/format/parse.rs
class ChronoParser {
  ChronoParser._(this._string);

  final _parsed = ChronoParsed();
  String _string;

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
    final (:parsed, :rest) = parseAndRemainder(string, items);
    if (rest.isNotEmpty) throw const ChronoParseException(.tooLong);
    return parsed;
  }

  /// Tries to parse given string into `parsed` with given formatting items.
  /// Returns `Ok` with a slice of the unparsed remainder.
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
  static ({ChronoParsed parsed, String rest}) parseAndRemainder(
    String string,
    List<ChronoFormatItem> items,
  ) {
    final parser = ChronoParser._(string);
    parser._parseAndRemainder(items);
    return (parsed: parser._parsed, rest: parser._string);
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
            ChronoFormatQuarter() => (1, false, (it) => _parsed.quarter = it),
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
            ChronoFormatWeekdayFromMon() => (
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

            case ChronoFormatRFC2822():
              // try_consume!(parse_rfc2822(parsed, s)),
              throw UnimplementedError();
            case ChronoFormatRFC3339():
              // // Used for the `%+` specifier, which has the description:
              // // "Same as `%Y-%m-%dT%H:%M:%S%.f%:z` (...)
              // // This format also supports having a `Z` or `UTC` in place of `%:z`."
              // // Use the relaxed parser to match this description.
              // try_consume!(parse_rfc3339_relaxed(parsed, s))
              throw UnimplementedError();
          }

        case ChronoFormatItemError():
          throw const ChronoParseException(.badFormat);
      }
    }
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

class ChronoParseException implements Exception {
  const ChronoParseException(this.kind);

  final ChronoParseExceptionKind kind;

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
