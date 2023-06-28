import 'package:fixed/fixed.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'date/date.dart';
import 'date/month/month.dart';
import 'date/month/year_month.dart';
import 'date/ordinal_date.dart';
import 'date/week/week_date.dart';
import 'date/week/year_week.dart';
import 'date/weekday.dart';
import 'date/year.dart';
import 'date_time/date_time.dart';
import 'date_time/instant.dart';
import 'time/duration.dart';
import 'time/time.dart';

// Date and time strings only use ASCII, hence we don't need to worry about
// proper Unicode handling.
final class Parser {
  Parser._(this._source);

  static Result<Instant, FormatException> parseInstant(String value) =>
      _parse(value, (it) => it._parseInstant());
  static Result<DateTime, FormatException> parseDateTime(String value) =>
      _parse(value, (it) => it._parseDateTime());
  static Result<Date, FormatException> parseDate(String value) =>
      _parse(value, (it) => it._parseDate());
  static Result<WeekDate, FormatException> parseWeekDate(String value) =>
      _parse(value, (it) => it._parseWeekDate());
  static Result<OrdinalDate, FormatException> parseOrdinalDate(
    String value,
  ) =>
      _parse(value, (it) => it._parseOrdinalDate());
  static Result<YearMonth, FormatException> parseYearMonth(String value) =>
      _parse(value, (it) => it._parseYearMonth());
  static Result<YearWeek, FormatException> parseYearWeek(String value) =>
      _parse(value, (it) => it._parseYearWeek());
  static Result<Time, FormatException> parseTime(String value) =>
      _parse(value, (it) => it._parseTime());

  static Result<T, FormatException> _parse<T extends Object>(
    String value,
    Result<T, FormatException> Function(Parser) parse,
  ) {
    final parser = Parser._(value);
    return parse(parser).andAlso(parser._requireEnd);
  }

  final String _source;
  int _offset = 0;

  // Date and Time

  Result<Instant, FormatException> _parseInstant() {
    return _parseDateTime().andAlso(() {
      const messageStart =
          'Expected “Z” or “z” to mark this date/time as UTC, but';

      if (_offset >= _source.length) {
        return _error(
          '$messageStart reached the end of the input string.',
          _offset,
        );
      }

      final character = _peek()!;
      if (character.toUpperCase() != 'Z') {
        return _error(
          '$messageStart found the following character: “$character”.',
          _offset,
        );
      }

      _offset++;
      return const Ok(unit);
    }).map((it) => it.inUtc);
  }

  Result<DateTime, FormatException> _parseDateTime() {
    return _parseDate()
        .andAlso(() => _requireDesignator('T', 'time', isCaseSensitive: false))
        .andThen((date) => _parseTime().map((it) => DateTime(date, it)));
  }

  Result<Date, FormatException> _parseDate() {
    return _parseYearMonth()
        .andAlso(() => _requireSeparator({'-'}, 'month', 'day'))
        .andThen(_parseDay);
  }

  Result<WeekDate, FormatException> _parseWeekDate() {
    return _parseYearWeek()
        .andAlso(() => _requireSeparator({'-'}, 'week number', 'weekday'))
        .andThen(
          (yearWeek) =>
              _parseWeekday().map((weekday) => WeekDate(yearWeek, weekday)),
        );
  }

  Result<OrdinalDate, FormatException> _parseOrdinalDate() {
    return _parseYear()
        .andAlso(() => _requireSeparator({'-'}, 'year', 'day of year'))
        .andThen((year) {
      final dayOfYear = _parseInt(
        'day of year',
        minDigits: 3,
        maxDigits: 3,
        minValue: 1,
        maxValue: year.lengthInDays.value,
      );
      return dayOfYear.map((it) => OrdinalDate.fromUnchecked(year, it));
    });
  }

  Result<YearMonth, FormatException> _parseYearMonth() {
    return _parseYear()
        .andAlso(() => _requireSeparator({'-'}, 'year', 'month'))
        .andThen(
          (year) => _parseMonth().map((it) => YearMonth(year, it)),
        );
  }

  Result<YearWeek, FormatException> _parseYearWeek() {
    return _parseYear()
        .andAlso(() => _requireSeparator({'-'}, 'year', 'week number'))
        .andThen(
          (year) => _parseWeek(year.numberOfWeeks).andThen(
            (it) => YearWeek.from(year, it).mapErr(FormatException.new),
          ),
        );
  }

  Result<Time, FormatException> _parseTime() {
    Result<int, FormatException> parse(String label, {required int maxValue}) {
      return _parseInt(
        label,
        minDigits: 2,
        maxDigits: 2,
        minValue: 0,
        maxValue: maxValue,
      );
    }

    return parse('hour', maxValue: 23)
        .andAlso(() => _requireSeparator({':'}, 'hour', 'minute'))
        .andThen(
          (hour) => parse('minute', maxValue: 59).map((it) => (hour, it)),
        )
        .andAlso(() => _requireSeparator({':'}, 'minute', 'second'))
        .andThen(
          (hourMinute) =>
              parse('second', maxValue: 59).map((it) => (hourMinute, it)),
        )
        .andThen((hourMinuteSecond) {
      return _maybeConsume('.')
          ? _parseIntRaw('fractional second', minDigits: 1).map(
              (it) => (
                hourMinuteSecond,
                FractionalSeconds(Fixed.fromInt(it.$1, scale: it.$2)),
              ),
            )
          : Ok((hourMinuteSecond, FractionalSeconds.zero));
    }).andThen((it) {
      final (((hour, minute), second), fraction) = it;
      return Time.from(hour, minute, second, fraction)
          .mapErr(FormatException.new);
    });
  }

  Result<Year, FormatException> _parseYear() {
    final Result<int, FormatException> value;
    switch (_peek()) {
      case '+':
        _offset++;
        value = _parseInt('year', minDigits: 4);
      case '-':
        _offset++;
        value = _parseInt('year', minDigits: 4).map((it) => -it);
      default:
        value = _parseInt('year', minDigits: 4, maxDigits: 4);
    }
    return value.map(Year.new);
  }

  Result<Month, FormatException> _parseMonth() {
    final value = _parseInt(
      'month',
      minDigits: 2,
      maxDigits: 2,
      minValue: Month.minNumber,
      maxValue: Month.maxNumber,
    );
    return value.map(Month.fromNumberThrowing);
  }

  Result<int, FormatException> _parseWeek(int numberOfWeeksInYear) {
    return _requireDesignator('W', 'week number').andThen(
      (_) => _parseInt(
        'week number',
        minDigits: 2,
        maxDigits: 2,
        minValue: 1,
        maxValue: numberOfWeeksInYear,
      ),
    );
  }

  Result<Date, FormatException> _parseDay(YearMonth yearMonth) {
    final value = _parseInt(
      'day',
      minDigits: 2,
      maxDigits: 2,
      minValue: 1,
      maxValue: yearMonth.lengthInDays.value,
    );
    return value.andThen((it) =>
        Date.fromYearMonthAndDay(yearMonth, it).mapErr(FormatException.new));
  }

  Result<Weekday, FormatException> _parseWeekday() {
    return _parseInt(
      'weekday',
      minDigits: 1,
      maxDigits: 1,
      minValue: Weekday.minNumber,
      maxValue: Weekday.maxNumber,
    ).map(Weekday.fromNumberUnchecked);
  }

  // Utils

  Result<int, FormatException> _parseInt(
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
    ).map((it) => it.$1);
  }

  Result<(int, int), FormatException> _parseIntRaw(
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
      return _error(
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
          return _error(
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
      return _error('Expected $range, but got $label = $value.', _offset);
    }
    return Ok((value, digitCount()));
  }

  @useResult
  Result<Unit, FormatException> _requireDesignator(
    String character,
    String label, {
    bool isCaseSensitive = true,
  }) {
    assert(character.length == 1);

    return _require(
      isValid: (it) => isCaseSensitive
          ? it == character
          : it.toUpperCase() == character.toUpperCase(),
      messageStart: () {
        return 'Expected the designator character “$character” to mark the '
            'start of the $label, but';
      },
    );
  }

  @useResult
  Result<Unit, FormatException> _requireSeparator(
    Set<String> validCharacters,
    String left,
    String right,
  ) {
    assert(validCharacters.every((it) => it.length == 1));

    return _require(
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

  @useResult
  Result<Unit, FormatException> _require({
    required bool Function(String character) isValid,
    required String Function() messageStart,
  }) {
    if (_offset >= _source.length) {
      return _error(
        '${messageStart()} reached the end of the input string.',
        _offset,
      );
    }

    final actual = _peek()!;
    if (!isValid(actual)) {
      return _error(
        '${messageStart()} found the following character: “$actual”.',
        _offset,
      );
    }

    _offset++;
    return const Ok(unit);
  }

  Result<Unit, FormatException> _requireEnd() {
    if (_offset == _source.length) return const Ok(unit);

    final remainingCount = _plural(
      _source.length - _offset,
      () => 'one remaining character',
      (it) => '$it remaining characters',
    );
    return _error(
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

  String? _peek() => _offset < _source.length ? _source[_offset] : null;

  @useResult
  Result<T, FormatException> _error<T extends Object>(
    String message,
    int offset,
  ) {
    return Err(FormatException(message, _source, offset));
  }

  String _plural(
    int value,
    String Function() singular,
    String Function(int) plural,
  ) =>
      value == 1 ? singular() : plural(value);
}

T unwrapParserResult<T extends Object>(Result<T, FormatException> result) {
  return switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw error,
  };
}

extension<T extends Object, E extends Object> on Result<T, E> {
  Result<T, E> andAlso<U extends Object>(Result<U, E> Function() op) =>
      andThen((it) => op().map((_) => it));
}
