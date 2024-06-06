import 'package:fixed/fixed.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import 'date/date.dart';
import 'date/month/month.dart';
import 'date/month/month_day.dart';
import 'date/month/year_month.dart';
import 'date/ordinal_date.dart';
import 'date/week/week_date.dart';
import 'date/week/year_week.dart';
import 'date/weekday.dart';
import 'date/year.dart';
import 'date_time/date_time.dart';
import 'time/duration.dart';
import 'time/time.dart';
import 'unix_epoch_timestamp.dart';

// Date and time strings only use ASCII, hence we don't need to worry about
// proper Unicode handling.
final class Parser {
  Parser._(this._source);

  static Result<Instant, FormatException> parseInstant(String value) =>
      _parse(value, (it) => it._parseInstant());
  static Result<UnixEpochNanoseconds, FormatException>
      parseUnixEpochNanoseconds(String value) {
    return _parse(
      value,
      (it) => it
          ._parseInstant(subSecondDigits: 9)
          .map((it) => it.roundToNanoseconds()),
    );
  }

  static Result<UnixEpochMicroseconds, FormatException>
      parseUnixEpochMicroseconds(String value) {
    return _parse(
      value,
      (it) => it
          ._parseInstant(subSecondDigits: 6)
          .map((it) => it.roundToMicroseconds()),
    );
  }

  static Result<UnixEpochMilliseconds, FormatException>
      parseUnixEpochMilliseconds(String value) {
    return _parse(
      value,
      (it) => it
          ._parseInstant(subSecondDigits: 3)
          .map((it) => it.roundToMilliseconds()),
    );
  }

  static Result<UnixEpochSeconds, FormatException> parseUnixEpochSeconds(
    String value,
  ) {
    return _parse(
      value,
      (it) =>
          it._parseInstant(subSecondDigits: 0).map((it) => it.roundToSeconds()),
    );
  }

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
  static Result<Year, FormatException> parseYear(String value) =>
      _parse(value, (it) => it._parseYear());
  static Result<YearMonth, FormatException> parseYearMonth(String value) =>
      _parse(value, (it) => it._parseYearMonth());
  static Result<YearWeek, FormatException> parseYearWeek(String value) =>
      _parse(value, (it) => it._parseYearWeek());
  static Result<MonthDay, FormatException> parseMonthDay(String value) =>
      _parse(value, (it) => it._parseMonthDay());

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

  Result<Instant, FormatException> _parseInstant({int? subSecondDigits}) {
    return _parseDateTime(subSecondDigits: subSecondDigits)
        .andAlso(
          () => _requireString(
            'Z',
            isCaseSensitive: false,
            messageStart: () =>
                'Expected “Z” or “z” to mark this date/time as UTC, but',
          ),
        )
        .map((it) => it.inUtc);
  }

  Result<DateTime, FormatException> _parseDateTime({int? subSecondDigits}) {
    return _parseDate()
        .andAlso(() => _requireDesignator('T', 'time', isCaseSensitive: false))
        .andThen(
          (date) => _parseTime(subSecondDigits: subSecondDigits)
              .map((it) => DateTime(date, it)),
        );
  }

  Result<Date, FormatException> _parseDate() {
    return _parseYearMonth()
        .andAlso(() => _requireSeparator({'-'}, 'month', 'day'))
        .andThen((yearMonth) {
      return _parseDay(maxLength: yearMonth.length.inDays).andThen((day) {
        return Date.fromYearMonthAndDay(yearMonth, day)
            .mapErr(FormatException.new);
      });
    });
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
        maxValue: year.length.inDays,
      );
      return dayOfYear.map((it) => OrdinalDate.from(year, it).unwrap());
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

  Result<MonthDay, FormatException> _parseMonthDay() {
    return _requireDesignator('--', 'month')
        .andThen((_) => _parseMonth())
        .andAlso(() => _requireSeparator({'-'}, 'month', 'day'))
        .andThen(
          (month) => _parseDay(maxLength: month.maxLength.inDays).andThen(
            (it) => MonthDay.from(month, it).mapErr(FormatException.new),
          ),
        );
  }

  Result<Time, FormatException> _parseTime({int? subSecondDigits}) {
    Result<int, FormatException> parse(String label, {required int maxValue}) =>
        _parseInt(label, minDigits: 2, maxDigits: 2, maxValue: maxValue);

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
      Result<FractionalSeconds, FormatException> parse() {
        return _parseIntRaw(
          'fractional second',
          minDigits: subSecondDigits ?? 1,
          maxDigits: subSecondDigits,
        ).map((it) => FractionalSeconds(Fixed.fromInt(it.$1, scale: it.$2)));
      }

      // ignore: omit_local_variable_types
      final Result<FractionalSeconds, FormatException> result =
          switch (subSecondDigits) {
        null => _maybeConsume('.') ? parse() : Ok(FractionalSeconds.zero),
        0 => Ok(FractionalSeconds.zero),
        _ => _requireSeparator({'.'}, 'second', 'fractional second')
            .andThen((_) => parse()),
      };
      return result.map((it) => (hourMinuteSecond, it));
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
    return value.map((it) => Month.fromNumber(it).unwrap());
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

  Result<int, FormatException> _parseDay({required int maxLength}) {
    return _parseInt(
      'day',
      minDigits: 2,
      maxDigits: 2,
      minValue: 1,
      maxValue: maxLength,
    );
  }

  Result<Weekday, FormatException> _parseWeekday() {
    return _parseInt(
      'weekday',
      maxDigits: 1,
      minValue: Weekday.minNumber,
      maxValue: Weekday.maxNumber,
    ).map((it) => Weekday.fromNumber(it).unwrap());
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
    String designator,
    String label, {
    bool isCaseSensitive = true,
  }) {
    return _requireString(
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

  @useResult
  Result<Unit, FormatException> _requireString(
    String string, {
    bool isCaseSensitive = true,
    required String Function() messageStart,
  }) {
    return _require(
      length: string.length,
      isValid: (it) => isCaseSensitive
          ? it == string
          : it.toUpperCase() == string.toUpperCase(),
      messageStart: messageStart,
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
    int length = 1,
    required bool Function(String string) isValid,
    required String Function() messageStart,
  }) {
    if (_offset >= _source.length) {
      return _error(
        '${messageStart()} reached the end of the input string.',
        _offset,
      );
    }

    final actual = _peek(length: length)!;
    if (!isValid(actual)) {
      return _error(
        '${messageStart()} found the following string: “$actual”.',
        _offset,
      );
    }

    _offset += length;
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

  String? _peek({int length = 1}) {
    return _offset + length <= _source.length
        ? _source.substring(_offset, _offset + length)
        : null;
  }

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
