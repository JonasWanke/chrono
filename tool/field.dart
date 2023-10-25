import 'package:chrono/chrono.dart';
import 'package:oxidized/oxidized.dart';
import 'package:supernova/supernova.dart' hide Weekday;

import 'line.dart';

@immutable
class Field {
  const Field(this.line, this.fieldIndex, this.value);

  final Line line;
  final int fieldIndex;
  final String value;

  void require(String expectedValue) {
    if (expectedValue == value) return;

    throwFormatException('Expected “$expectedValue”');
  }

  ParseResult<Month> parseMonth() {
    final month =
        getByWord(Month.values.associate((it) => MapEntry(it.name, it)));
    if (month == null) return Err(ParseException(this, 'Invalid month name'));
    return Ok(month);
  }

  ParseResult<Weekday> parseWeekday([int start = 0, int? end]) {
    final weekday = getByWord(
      Weekday.values.associate((it) => MapEntry(it.name, it)),
      start: start,
      end: end,
    );
    if (weekday == null) {
      return Err(ParseException(this, 'Invalid weekday name'));
    }
    return Ok(weekday);
  }

  /// Original: `byword`
  T? getByWord<T extends Object>(
    Map<String, T> lookup, {
    int start = 0,
    int? end,
  }) {
    // TODO: Do we need this remaining code?
    // if (word == NULL || table == NULL) return NULL;

    final lowerCaseValue = value.substring(start, end).toLowerCase();

    // Look for exact match.
    final exactMatch = lookup.entries
        .firstOrNullWhere((it) => it.key.toLowerCase() == lowerCaseValue)
        ?.value;
    if (exactMatch != null) return exactMatch;

    // Look for inexact match.
    final prefixMatches = lookup.entries
        .where((it) => it.key.toLowerCase().startsWith(lowerCaseValue))
        .toList();
    return prefixMatches.singleOrNull?.value;
  }

  /// Convert a string of one of the following forms into a number of seconds:
  /// `h`, `-h`, `hh:mm`, `-hh:mm`, `hh:mm:ss`, `-hh:mm:ss`
  ///
  /// Original: `gethms`
  Result<SecondsDuration, ParseException> parseHms({int? end}) {
    if (value.isEmpty) return const Ok(Seconds(0));

    final regex = RegExp(
      r'^(?<sign>-?)(?<hours>\d{1,2})(:(?<minutes>\d{1,2}))?(:(?<seconds>\d{1,2}))?(?:\.\d+)?$',
    );
    final match = regex.firstMatch(value.substring(0, end));
    if (match == null) {
      return Err(ParseException(this, "Couldn't parse pattern."));
    }

    final isNegative = match.namedGroup('sign')!.isNotEmpty;
    final signMultiplier = isNegative ? -1 : 1;

    final hours = int.parse(match.namedGroup('hours')!);
    final minutes = match.namedGroup('minutes')?.let(int.parse) ?? 0;
    final seconds = match.namedGroup('seconds')?.let(int.parse) ?? 0;
    if (minutes >= Minutes.perHour) {
      return Err(ParseException(this, 'Minutes are too large: $minutes'));
    }
    if (seconds >= Seconds.perMinute) {
      return Err(ParseException(this, 'Seconds are too large: $seconds'));
    }

    // TODO: handle fractionals or round them

    if (seconds == 0) {
      if (minutes == 0) return Ok(Hours(hours) * signMultiplier);
      return Ok((Minutes(minutes) + Hours(hours)) * signMultiplier);
    }
    return Ok(
      (Seconds(seconds) + Minutes(minutes) + Hours(hours)) * signMultiplier,
    );
  }

  /// OriginaL: `namecheck`
  bool isValidName() {
    /// Benign characters in a portable file name.
    const benign = '-/_'
        'abcdefghijklmnopqrstuvwxyz'
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    /// Non-control chars in the POSIX portable character set, excluding the
    /// benign characters.
    const printableAndNotBenign = " !\"#\$%&'()*+,.0123456789:;<=>?@[\\]^`{|}~";

    var componentStartIndex = 0;
    for (var i = 0; i < value.length; i++) {
      final character = value[i];

      if (!benign.contains(character)) {
        final characterString = printableAndNotBenign.contains(character)
            ? character
            : 'U+${character.runes.single.toRadixString(16)}';
        logger.warning('Name “$value” contains byte “$characterString”');
      }

      if (character == '/') {
        if (!_isValidNameComponent(componentStartIndex, i)) {
          return false;
        }
        componentStartIndex = i + 1;
      }
    }
    return _isValidNameComponent(componentStartIndex, value.length);
  }

  /// Original: `componentcheck`
  bool _isValidNameComponent(int start, int end) {
    const maxComponentLength = 14;

    final component = value.substring(start, end);
    if (component.isEmpty) {
      if (value.isEmpty) {
        logError('Empty file name');
      } else {
        logError(
          start == 0
              ? 'File name “$value” begins with “/”'
              : end == value.length
                  ? 'File name “$value” ends with “/”'
                  : 'File name “$value” contains “/”',
        );
      }
      return false;
    }
    if (component.length <= 2 &&
        component.startsWith('.') &&
        component.endsWith('.')) {
      logError('File name “$value” contains “$component” component');
      return false;
    }
    if (component[0] == '-') {
      logWarning('File name “$value” component contains leading “-”');
    }
    if (component.length > maxComponentLength) {
      logWarning(
        'File name “$value” contains overlength component “$component”',
      );
    }
    return true;
  }

  void logWarning(String message) {
    logger.warning(
      '${line.fileName}, line ${line.lineIndex}, field $fieldIndex: $message',
      value,
    );
  }

  void logError(String message) {
    logger.error(
      '${line.fileName}, line ${line.lineIndex}, field $fieldIndex: $message',
      value,
    );
  }

  Never throwFormatException(String message) {
    throw FormatException(
      '${line.fileName}, line ${line.lineIndex}, field $fieldIndex: $message',
      value,
    );
  }

  @override
  String toString() {
    return '${line.fileName}, line ${line.lineIndex}, field $fieldIndex: “$value”';
  }
}

typedef ParseResult<T extends Object> = Result<T, ParseException>;

@immutable
final class ParseException {
  ParseException(Field this.field, this.message) : line = field.line;
  const ParseException.line(this.line, this.message) : field = null;
  const ParseException._(this.line, this.field, this.message);

  final Line line;
  final Field? field;
  final String message;

  ParseException withContext(String context) =>
      ParseException._(line, field, '$context:\n$message');

  @override
  String toString() => '$message\n${field ?? line}';
}
