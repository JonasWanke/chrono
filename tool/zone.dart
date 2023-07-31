import 'package:chrono/chrono.dart';
import 'package:supernova/supernova.dart';

import 'field.dart';
import 'line.dart';
import 'rule.dart';
import 'zone_information_compiler.dart';

@immutable
final class Zone {
  const Zone({
    required this.name,
    required this.rulesWithEnd,
    required this.lastRule,
  });

  /// Original: `inzone`
  static (String, ZoneRule, Seconds?)? parse(Line line) {
    line.fields.first.require('Zone');
    if (line.fields.length < 5 || line.fields.length > 9) {
      line.logError('Wrong number of fields on zone line');
      return null;
    }

    // TODO: Handle `-l localtime` argument
    // TODO: Handle `-p posixrules` argument

    if (!line.fields.second.isValidName()) return null;

    final result = _parseHelper(line.fields.sublist(2));
    if (result == null) return null;
    final (ruleName, ruleEnd) = result;

    return (line.fields.second.value, ruleName, ruleEnd);
  }

  /// Original: `inzcont`
  static (ZoneRule, Seconds?)? parseContinuation(Line line) {
    if (line.fields.length < 3 || line.fields.length > 7) {
      line.logError('Wrong number of fields on zone continuation line');
    }

    return _parseHelper(line.fields);
  }

  /// Original: `inzsub`
  static (ZoneRule, Seconds?)? _parseHelper(List<Field> fields) {
    final standardOffsetField = fields.first;
    final ruleField = fields[1];
    final formatField = fields[2];

    final standardOffset =
        standardOffsetField.parseHms(errorText: 'Invalid UT offset');
    if (standardOffset == null) return null;

    final formatSpecifierIndex = formatField.value.indexOfOrNull('%');
    String? formatSpecifier;
    if (formatSpecifierIndex != null) {
      if (formatSpecifierIndex == formatField.value.length - 1 ||
          formatField.value.contains('/')) {
        formatField.logError('Invalid abbreviation format');
        return null;
      }

      formatSpecifier = formatField.value[formatSpecifierIndex + 1];
      if ((formatSpecifier != 's' && formatSpecifier != 'z') ||
          formatField.value.substring(formatSpecifierIndex + 1).contains('%')) {
        formatField.logError('Invalid abbreviation format');
        return null;
      }
    }

    Seconds? untilEpochTime;
    if (fields.length > 3) {
      final untilYearField = fields[3];
      final untilMonthField = fields.elementAtOrNull(4);
      final untilDayField = fields.elementAtOrNull(5);
      final untilTimeField = fields.elementAtOrNull(6);

      // TODO: Simplify this to a `Year`?
      final untilYear = RuleClause.parseStartYear(untilYearField);
      if (untilYear == null) return null;

      final Month untilMonth;
      if (untilMonthField == null) {
        untilMonth = Month.january;
      } else {
        final month = untilMonthField.parseMonth();
        if (month == null) return null;
        untilMonth = month;
      }

      final DayCode untilDayCode;
      if (untilDayField == null) {
        untilDayCode = const DayCode.dayOfMonth(1);
      } else {
        final dayCode = DayCode.parse(untilDayField, untilMonth);
        if (dayCode == null) return null;
        untilDayCode = dayCode;
      }

      final TimeWithZoneInfo untilTime;
      if (untilTimeField == null) {
        untilTime = (time: const Seconds(0), isStd: false, isUt: false);
      } else {
        final time = RuleClause.parseTime(untilTimeField);
        if (time == null) return null;
        untilTime = time;
      }

      untilEpochTime = calculateRuleClauseEpochTime(
        untilMonth,
        untilDayCode,
        untilTime.time,
        untilYear,
      );
    }

    final rule = ZoneRule(
      ruleName: ruleField.value.emptyToNull,
      standardOffset: standardOffset,
    );
    return (rule, untilEpochTime);
  }

  final String name;
  // TODO: Can/should ends be a local `DateTime` instead?
  final List<(ZoneRule, Seconds)> rulesWithEnd;
  final ZoneRule lastRule;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('Zone ');
    buffer.write(name);
    buffer.writeln(':');
    for (final (rule, end) in rulesWithEnd) {
      buffer.write('• ');
      buffer.write(rule);
      buffer.write(' until ');
      buffer.writeln(end);
    }
    buffer.write(lastRule);
    return buffer.toString();
  }
}

@immutable
final class ZoneRule {
  const ZoneRule({required this.ruleName, required this.standardOffset});

  final String? ruleName;
  final SecondsDuration standardOffset;

  @override
  String toString() {
    if (ruleName == null) return 'Offset $standardOffset';
    return 'Rule $ruleName with offset $standardOffset';
  }
}
