import 'dart:math' as math;

import 'date/date.dart';
import 'date/month/month.dart';
import 'date/month/month_day.dart';
import 'date/month/year_month.dart';
import 'date/week/iso_year_week.dart';
import 'date/weekday.dart';
import 'date/year.dart';
import 'date_time/date_time.dart';
import 'instant.dart';
import 'time/time.dart';
import 'utils.dart';

// Date and time strings only use ASCII, hence we don't need to worry about
// proper Unicode handling.
final class Parser {
  Parser._(this._source);

  static Instant parseInstant(String value) =>
      _parse(value, (it) => it._parseInstant());
  static CDateTime parseDateTime(String value) =>
      _parse(value, (it) => it._parseDateTime());
  static Date parseDate(String value) => _parse(value, (it) => it._parseDate());
  static Date parseWeekDate(String value) =>
      _parse(value, (it) => it._parseWeekDate());
  static Date parseOrdinalDate(String value) =>
      _parse(value, (it) => it._parseOrdinalDate());
  static Year parseYear(String value) => _parse(value, (it) => it._parseYear());
  static YearMonth parseYearMonth(String value) =>
      _parse(value, (it) => it._parseYearMonth());
  static IsoYearWeek parseIsoYearWeek(String value) =>
      _parse(value, (it) => it._parseIsoYearWeek());
  static MonthDay parseMonthDay(String value) =>
      _parse(value, (it) => it._parseMonthDay());

  static Time parseTime(String value) => _parse(value, (it) => it._parseTime());

  static T _parse<T extends Object>(String value, T Function(Parser) parse) {
    final parser = Parser._(value);
    final result = parse(parser);
    parser._requireEnd();
    return result;
  }

  final String _source;
  int _offset = 0;

  // Date and Time

  Instant _parseInstant() {
    final dateTime = _parseDateTime();

    _requireString(
      'Z',
      isCaseSensitive: false,
      messageStart: () =>
          'Expected “Z” or “z” to mark this date/time as UTC, but',
    );
    return dateTime.inUtc;
  }

  CDateTime _parseDateTime() {
    final date = _parseDate();
    _requireDesignator('T', 'time', isCaseSensitive: false);
    final time = _parseTime();
    return CDateTime(date, time);
  }

  Date _parseDate() {
    final yearMonth = _parseYearMonth();
    _requireSeparator({'-'}, 'month', 'day');
    final day = _parseDay(maxLength: yearMonth.length.inDays);
    return Date.fromYearMonthAndDay(yearMonth, day);
  }

  Date _parseWeekDate() {
    final isoYearWeek = _parseIsoYearWeek();
    _requireSeparator({'-'}, 'week number', 'weekday');
    final weekday = _parseWeekday();
    return Date.fromIsoYearWeekAndWeekday(isoYearWeek, weekday);
  }

  Date _parseOrdinalDate() {
    final year = _parseYear();
    _requireSeparator({'-'}, 'year', 'day of year');
    final dayOfYear = _parseInt(
      'day of year',
      minDigits: 3,
      maxDigits: 3,
      minValue: 1,
      maxValue: year.length.inDays,
    );
    return Date.fromYearAndOrdinal(year, dayOfYear);
  }

  YearMonth _parseYearMonth() {
    final year = _parseYear();
    _requireSeparator({'-'}, 'year', 'month');
    final month = _parseMonth();
    return YearMonth(year, month);
  }

  IsoYearWeek _parseIsoYearWeek() {
    final year = _parseYear();
    _requireSeparator({'-'}, 'year', 'week number');
    final week = _parseWeek(year.numberOfIsoWeeks);
    return IsoYearWeek.from(year, week);
  }

  MonthDay _parseMonthDay() {
    _requireDesignator('--', 'month');
    final month = _parseMonth();
    _requireSeparator({'-'}, 'month', 'day');
    final day = _parseDay(maxLength: month.maxLength.inDays);
    return MonthDay.from(month, day);
  }

  Time _parseTime() {
    int parse(String label, {required int maxValue}) =>
        _parseInt(label, minDigits: 2, maxDigits: 2, maxValue: maxValue);

    final hour = parse('hour', maxValue: 23);
    _requireSeparator({':'}, 'hour', 'minute');
    final minute = parse('minute', maxValue: 59);
    _requireSeparator({':'}, 'minute', 'second');
    final second = parse('second', maxValue: 59);
    final fraction = _maybeConsume('.')
        ? _parseIntRaw(
            'fractional second',
            maxDigits: 9,
          ).let((it) => it.$1 * math.pow(10, 9 - it.$2).toInt())
        : 0;
    return Time.from(hour, minute, second, 0, 0, fraction);
  }

  Year _parseYear() {
    final int value;
    switch (_peek()) {
      case '+':
        _offset++;
        value = _parseInt('year', minDigits: 4);
      case '-':
        _offset++;
        value = -_parseInt('year', minDigits: 4);
      default:
        value = _parseInt('year', minDigits: 4, maxDigits: 4);
    }
    return Year(value);
  }

  Month _parseMonth() {
    final value = _parseInt(
      'month',
      minDigits: 2,
      maxDigits: 2,
      minValue: Month.minNumber,
      maxValue: Month.maxNumber,
    );
    return Month.fromNumber(value);
  }

  int _parseWeek(int numberOfWeeksInYear) {
    _requireDesignator('W', 'week number');
    return _parseInt(
      'week number',
      minDigits: 2,
      maxDigits: 2,
      minValue: 1,
      maxValue: numberOfWeeksInYear,
    );
  }

  int _parseDay({required int maxLength}) {
    return _parseInt(
      'day',
      minDigits: 2,
      maxDigits: 2,
      minValue: 1,
      maxValue: maxLength,
    );
  }

  Weekday _parseWeekday() {
    final number = _parseInt(
      'weekday',
      maxDigits: 1,
      minValue: Weekday.minNumber,
      maxValue: Weekday.maxNumber,
    );
    return Weekday.fromNumber(number);
  }

  // Utils

  int _parseInt(
    String label, {
    int minDigits = 1,
    int? maxDigits,
    int minValue = 0,
    int? maxValue,
  }) {
    return _parseIntRaw(
      label,
      minDigits: minDigits,
      maxDigits: maxDigits,
      minValue: minValue,
      maxValue: maxValue,
    ).$1;
  }

  (int, int) _parseIntRaw(
    String label, {
    int minDigits = 1,
    int? maxDigits,
    int minValue = 0,
    int? maxValue,
  }) {
    assert(maxDigits == null || maxDigits >= 1);
    assert(maxDigits == null || minDigits <= maxDigits);
    assert(minValue >= 0);
    assert(maxValue == null || minValue <= maxValue);

    String digitConstraintsString() {
      String minDigitsString() =>
          _plural(minDigits, () => '1 digit', (it) => '$it digits');
      return switch (maxDigits) {
        null => 'at least ${minDigitsString()}',
        _ when minDigits == maxDigits => 'exactly ${minDigitsString()}',
        _ => '$minDigits to $maxDigits digits',
      };
    }

    if (_offset + minDigits > _source.length) {
      final remainingCharsString = _plural(
        _source.length - _offset,
        () => 'there is only 1 character left',
        (it) => it == 0
            ? 'reached the end of the input string'
            : 'there are only $it characters left',
      );
      _error(
        'Tried parsing the $label as an integer with '
        '${digitConstraintsString()}, but $remainingCharsString.',
        _offset,
      );
    }

    var value = 0;
    final initialOffset = _offset;
    int digitCount() => _offset - initialOffset;
    while (_offset < _source.length &&
        (maxDigits == null || digitCount() < maxDigits)) {
      final character = _peek()!;
      final digit = character.codeUnitAt(0) - '0'.codeUnitAt(0);
      if (digit < 0 || digit > 9) {
        if (digitCount() < minDigits) {
          _error(
            'Tried parsing the $label as an integer with '
            '${digitConstraintsString()}, but found the following character: '
            '“$character”.',
            _offset + 1,
          );
        }
        break;
      }

      value = value * 10 + digit;
      _offset++;
    }
    if (value < minValue || (maxValue != null && value > maxValue)) {
      final range = maxValue == null
          ? '$label ≥ $minValue'
          : '$minValue ≤ $label ≤ $maxValue';
      _error('Expected $range, but got $label = $value.', _offset);
    }
    return (value, digitCount());
  }

  void _requireDesignator(
    String designator,
    String label, {
    bool isCaseSensitive = true,
  }) {
    _requireString(
      designator,
      isCaseSensitive: isCaseSensitive,
      messageStart: () {
        final designatorString = isCaseSensitive
            ? '“$designator”'
            : '“${designator.toLowerCase()}” or “${designator.toUpperCase()}”';
        return 'Expected the designator $designatorString to mark the start of '
            'the $label, but';
      },
    );
  }

  void _requireString(
    String string, {
    bool isCaseSensitive = true,
    required String Function() messageStart,
  }) {
    _require(
      length: string.length,
      isValid: (it) => isCaseSensitive
          ? it == string
          : it.toUpperCase() == string.toUpperCase(),
      messageStart: messageStart,
    );
  }

  void _requireSeparator(
    Set<String> validCharacters,
    String left,
    String right,
  ) {
    assert(validCharacters.every((it) => it.length == 1));

    _require(
      isValid: (it) => validCharacters.contains(it),
      messageStart: () {
        final charactersMessage = _plural(
          validCharacters.length,
          () => 'the character “${validCharacters.single}”',
          (_) => 'one of the characters “${validCharacters.join('”, “')}”',
        );
        return 'Expected $charactersMessage to separate $left and $right, but';
      },
    );
  }

  void _require({
    int length = 1,
    required bool Function(String string) isValid,
    required String Function() messageStart,
  }) {
    if (_offset >= _source.length) {
      _error('${messageStart()} reached the end of the input string.', _offset);
    }

    final actual = _peek(length: length)!;
    if (!isValid(actual)) {
      _error(
        '${messageStart()} found the following string: “$actual”.',
        _offset,
      );
    }

    _offset += length;
  }

  void _requireEnd() {
    if (_offset == _source.length) return;

    final remainingCount = _plural(
      _source.length - _offset,
      () => 'one remaining character',
      (it) => '$it remaining characters',
    );
    _error(
      'Expected the end of the input string, but found $remainingCount: '
      '“${_source.substring(_offset)}”.',
      _offset,
    );
  }

  bool _maybeConsume(String character) {
    if (_peek() != character) return false;

    _offset++;
    return true;
  }

  String? _peek({int length = 1}) {
    return _offset + length <= _source.length
        ? _source.substring(_offset, _offset + length)
        : null;
  }

  Never _error<T extends Object>(String message, int offset) {
    throw FormatException(message, _source, offset);
  }

  String _plural(
    int value,
    String Function() singular,
    String Function(int) plural,
  ) => value == 1 ? singular() : plural(value);
}
