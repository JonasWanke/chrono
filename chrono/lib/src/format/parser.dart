import '../../chrono.dart';

/// This date and time parser is:
///
/// - Greedy. It will consume the longest possible prefix. For example, `April`
///   is always consumed entirely when the long month name is requested; it
///   equally accepts `Apr`, but prefers the longer prefix in this case.
/// - Strict by default: it only accepts what the formatter prints for the same
///   items.
///   - Numbers must match their `ChronoPadding`. For example,
///     `ChronoPadding.zero` requires exactly the formatting width in digits,
///     and no whitespace is accepted before numbers unless the padding is
///     `ChronoPadding.space`.
///   - Timezone offsets contain a colon exactly if `printColon` is `true`, and
///     no whitespace.
///   - Fixed-accuracy subseconds require the dot and all digits.
/// - Lenient if `isLenient` is `true`: padding is completely ignored, so one
///   can prepend any number of whitespace then any number of zeroes before
///   numbers. Offsets accept an optional colon surrounded by whitespace, and
///   subseconds can be omitted.
/// - (Still) obeying the intrinsic parsing width. This allows, for example,
///   parsing `HHMMSS`.
// Based on Rust Chrono's parser: https://github.com/chronotope/chrono/blob/3ffcd1b107fd3085bc184a1f5f7445b97a0d655f/src/format/parse.rs
class ChronoParser._(var String _string, {final bool _isLenient = false}) {
  final _initialLength = _string.length;
  final _parsed = ChronoParsed();

  /// The item that's currently being parsed and where it started, for error
  /// reporting.
  ChronoFormatItem? _currentItem;
  int? _currentItemStart;

  /// Tries to parse given [string] with given formatting [items].
  ///
  /// Returns [ChronoParsed] when the entire string has been parsed. There
  /// should be no trailing string after parsing; use a stray
  /// [ChronoFormatItemSpace] to trim whitespaces.
  static ChronoParsed parse(
    String string,
    List<ChronoFormatItem> items, {
    bool isLenient = false,
  }) {
    final (:parsed, :rest) = parseAndRest(string, items, isLenient: isLenient);
    if (rest.isNotEmpty) {
      throw ChronoParseException(
        .tooLong,
        source: string,
        offset: string.length - rest.length,
      );
    }
    return parsed;
  }

  /// Tries to parse given string into `parsed` with the given formatting items
  /// and also returns the remaining String.
  static ({ChronoParsed parsed, String rest}) parseAndRest(
    String string,
    List<ChronoFormatItem> items, {
    bool isLenient = false,
  }) {
    final parser = ChronoParser._(string, isLenient: isLenient);
    parser._withContext(string, () => parser._parseAndRemainder(items));
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
    parser._withContext(string, () {
      parser._parseRfc3339();
      if (parser._string.isNotEmpty) {
        throw const ChronoParseException(.tooLong);
      }
    });
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
    parser._withContext(string, () {
      parser._parseRfc2822();
      if (parser._string.isNotEmpty) {
        throw const ChronoParseException(.tooLong);
      }
    });
    return parser._parsed;
  }

  /// Runs [body] and adds the [source], the offset, and the current item to any
  /// [ChronoParseException] thrown without them.
  void _withContext(String source, void Function() body) {
    try {
      body();
    } on ChronoParseException catch (e) {
      if (e.source != null) rethrow;

      throw ChronoParseException(
        e.kind,
        source: source,
        offset: _currentItemStart ?? _initialLength - _string.length,
        item: _currentItem,
      );
    }
  }

  void _parseAndRemainder(List<ChronoFormatItem> items) {
    for (final item in items) {
      _currentItem = item;
      _currentItemStart = _initialLength - _string.length;
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
            ChronoFormatTimestamp() => (
              null,
              true,
              (it) => _parsed.timestamp = TimeDelta(seconds: it),
            ),
          };
          set(
            _isLenient
                ? _scanLenientNumeric(width, signed: signed)
                : _scanStrictNumeric(width, signed: signed, item.padding),
          );

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

            case ChronoFormatSubsecond(:final accuracy, :final dot):
              if (dot) {
                if (!_string.startsWith('.')) {
                  // Only a variable number of digits can be omitted entirely.
                  if (!_isLenient && accuracy != .variable) {
                    throw ChronoParseException(
                      _string.isEmpty ? .tooShort : .invalid,
                    );
                  }
                  break;
                }
                _string = _string.substring(1);
              }

              _parsed.nanosecond = switch (accuracy.digits) {
                null => _scanNanosecond(),
                final digits => _scanNanosecondFixed(digits),
              };

            case ChronoFormatTimezoneName():
              // Names are ambiguous and can't be mapped to an offset, so
              // silently skipping them would discard information.
              throw const ChronoParseException(.badFormat);

            case ChronoFormatTimezoneOffset(
              :final precision,
              :final allowZulu,
              :final printColon,
            ):
              if (_isLenient) _string = _string.trimLeft();
              _parsed.offset = _scanTimezoneOffset(
                precision: precision,
                separator: _isLenient
                    ? r'\s*:?\s*'
                    : printColon
                    ? ':'
                    : '',
                allowZulu: allowZulu,
                allowTzMinusSign: true,
              );
          }
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
      precision: .minutes,
      separator: ':',
      allowZulu: true,
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
        precision: .minutes,
        separator: '',
        allowZulu: false,
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

  /// Scans a number, ignoring the padding and trimming whitespace before it.
  int _scanLenientNumeric(int? width, {required bool signed}) {
    _string = _string.trimLeft();
    if (!signed) return _scanNumber(1, width);

    if (_string.startsWith('-')) {
      _string = _string.substring(1);
      return -_scanNumber(1, null);
    } else if (_string.startsWith('+')) {
      _string = _string.substring(1);
      return _scanNumber(1, null);
    } else {
      // If there is no explicit sign, we respect the original [width].
      return _scanNumber(1, width);
    }
  }

  /// Scans a number exactly as the formatter prints it for [padding], with
  /// [width] as both the formatting and the (maximum) parsing width.
  ///
  /// - [ChronoPadding.zero]: padded with zeros to the formatting width.
  /// - [ChronoPadding.space]: padded with spaces to the formatting width.
  /// - [ChronoPadding.none]: no padding.
  ///
  /// In all cases, a number is only padded to the formatting width and has no
  /// leading zeros beyond that. The sign counts towards the formatting width,
  /// except for zero-padded signed items (years).
  /// A `+` is only accepted for numbers that are wider than the formatting
  /// width, and `-` only for non-zero numbers.
  int _scanStrictNumeric(
    int? width,
    ChronoPadding padding, {
    required bool signed,
  }) {
    final formatWidth = width ?? 1;

    var spaces = 0;
    if (padding == .space) {
      while (spaces < _string.length && _string[spaces] == ' ') {
        spaces++;
      }
    }
    final signStart = spaces;
    final sign = signed && signStart < _string.length
        ? switch (_string[signStart]) {
            '-' || '+' => _string[signStart],
            _ => null,
          }
        : null;
    final signLength = sign == null ? 0 : 1;
    _string = _string.substring(signStart + signLength);

    final firstDigit = _string.isEmpty ? null : _string[0];
    final lengthBefore = _string.length;
    // Without a sign, we respect the original [width].
    final value = _scanNumber(1, sign == null ? width : null);
    final digits = lengthBefore - _string.length;

    // Signed items (years) don't count the sign towards the width of zero
    // padding, like in ISO 8601's expanded representation (`-0005`).
    final paddedDigits = padding == .zero && signed
        ? formatWidth
        : formatWidth - signLength;
    final hasLeadingZeros = digits > 1 && firstDigit == '0';
    final isValid = switch (padding) {
      .zero =>
        digits >= paddedDigits && (digits == paddedDigits || firstDigit != '0'),
      .space =>
        !hasLeadingZeros &&
            spaces == (paddedDigits - digits).clamp(0, paddedDigits),
      .none => !hasLeadingZeros,
    };
    final isSignValid = switch (sign) {
      // Items without a width (timestamps) never print a `+`.
      '+' => width != null && digits > formatWidth,
      '-' => value != 0,
      _ => true,
    };
    if (!isValid || !isSignValid) throw const ChronoParseException(.invalid);

    return sign == '-' ? -value : value;
  }

  /// The maximum number of digits for numbers without a `maxDigits`, so that
  /// the result always fits into a 64-bit integer.
  static const _maxUnboundedDigits = 18;

  /// Tries to parse the non-negative number from [minDigits] to [maxDigits].
  ///
  /// The absence of digits at all is an unconditional error. More than
  /// [_maxUnboundedDigits] digits are an [ChronoParseExceptionKind.outOfRange]
  /// error if [maxDigits] is `null`.
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

      if (digits == _maxUnboundedDigits) {
        throw const ChronoParseException(.outOfRange);
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

  /// Parses a timezone offset.
  ///
  /// The [precision] determines which parts (hours, minutes, and seconds) are
  /// required, optional, or not allowed, just like when formatting.
  ///
  /// The [separator] is a regular expression matching the text between two
  /// parts. Optional parts are only consumed, including their separator, if
  /// they are present.
  ///
  /// The [allowZulu] flag allows `Z` (or `z`) for a zero offset.
  ///
  /// The [allowTzMinusSign] flag allows the timezone offset negative character
  /// to also be `−` MINUS SIGN (U+2212) in addition to the typical
  /// ASCII-compatible `-` HYPHEN-MINUS (U+2D). This is part of
  /// [RFC 3339 & ISO 8601](https://en.wikipedia.org/w/index.php?title=ISO_8601&oldid=1114309368#Time_offsets_from_UTC)
  TimeDelta _scanTimezoneOffset({
    required TimezoneOffsetPrecision precision,
    required String separator,
    required bool allowZulu,
    required bool allowTzMinusSign,
  }) {
    if (allowZulu &&
        _string.isNotEmpty &&
        (_string[0] == 'Z' || _string[0] == 'z')) {
      _string = _string.substring(1);
      return TimeDelta();
    }

    final isNegative = switch (_string.isNotEmpty ? _string[0] : null) {
      '+' => false, // PLUS SIGN (U+2B)
      '-' => true, // HYPHEN-MINUS (U+2D)
      '−' when allowTzMinusSign => true, // MINUS SIGN (U+2212)
      null => throw const ChronoParseException(.tooShort),
      _ => throw const ChronoParseException(.invalid),
    };
    _string = _string.substring(1);

    final separatorPattern = RegExp(separator);
    final hours = _scanOffsetPart(99, separatorPattern: RegExp(''));
    final (
      _Presence minutesPresence,
      _Presence secondsPresence,
    ) = switch (precision) {
      .hours => (.absent, .absent),
      .optionalMinutes => (.optional, .absent),
      .minutes => (.required, .absent),
      .optionalMinutesAndSeconds => (.optional, .optional),
      .optionalSeconds => (.required, .optional),
      .seconds => (.required, .required),
    };
    final minutes = _scanOptionalOffsetPart(minutesPresence, separatorPattern);
    // Seconds can only follow minutes.
    final seconds = minutes == null
        ? null
        : _scanOptionalOffsetPart(secondsPresence, separatorPattern);

    final result = TimeDelta(
      hours: hours,
      minutes: minutes ?? 0,
      seconds: seconds ?? 0,
    );
    return isNegative ? -result : result;
  }

  /// Scans a part of a timezone offset that's [_Presence.required],
  /// [_Presence.optional], or [_Presence.absent].
  ///
  /// Returns `null` if the part is absent.
  int? _scanOptionalOffsetPart(_Presence presence, RegExp separatorPattern) {
    switch (presence) {
      case .absent:
        return null;
      case .optional:
        final match = RegExp('${separatorPattern.pattern}\\d\\d')
            .matchAsPrefix(_string);
        if (match == null) return null;
        return _scanOffsetPart(59, separatorPattern: separatorPattern);
      case .required:
        return _scanOffsetPart(59, separatorPattern: separatorPattern);
    }
  }

  /// Consumes [separatorPattern] and two digits, which must be at most
  /// [maxValue].
  int _scanOffsetPart(int maxValue, {required RegExp separatorPattern}) {
    final separator = separatorPattern.matchAsPrefix(_string);
    if (separator == null) {
      throw ChronoParseException(_string.isEmpty ? .tooShort : .invalid);
    }
    _string = _string.substring(separator.end);

    if (_string.length < 2) throw const ChronoParseException(.tooShort);
    final tens = _string.codeUnitAt(0) - 0x30;
    final ones = _string.codeUnitAt(1) - 0x30;
    if (tens < 0 || tens > 9 || ones < 0 || ones > 9) {
      throw const ChronoParseException(.invalid);
    }

    final value = tens * 10 + ones;
    if (value > maxValue) throw const ChronoParseException(.outOfRange);

    _string = _string.substring(2);
    return value;
  }
}

enum _Presence { required, optional, absent }

/// Thrown when a string can't be parsed.
class const ChronoParseException(
  final ChronoParseExceptionKind kind, {

  /// The string that was parsed, if known.
  @override final String? source,

  /// The offset in [source] where the failing [item] (or, when parsing RFC 3339
  /// and RFC 2822, the failing token) started, if known.
  @override final int? offset,

  /// The format item that couldn't be parsed, if any.
  final ChronoFormatItem? item,
}) implements FormatException {
  @override
  String get message => kind.toString();

  @override
  String toString() {
    final buffer = StringBuffer('ChronoParseException: $message');
    if (item != null) buffer.write(' (parsing $item)');
    final source = this.source;
    if (source != null) {
      buffer.write(' in “$source”');
      if (offset != null) buffer.write(' at offset $offset');
    }
    return buffer.toString();
  }
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
