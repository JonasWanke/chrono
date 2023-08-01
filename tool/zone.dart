import 'package:chrono/chrono.dart';
import 'package:supernova/supernova.dart';

import 'field.dart';
import 'line.dart';
import 'rule.dart';
import 'zone_information_compiler.dart';

part 'zone.freezed.dart';

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
    final nameField = fields[2];

    final standardOffset =
        standardOffsetField.parseHms(errorText: 'Invalid UT offset');
    if (standardOffset == null) return null;

    final type = ruleField.value.isEmpty
        ? const ZoneRuleType.none()
        : ruleField.parseHms(errorText: null)?.let(ZoneRuleType.offset) ??
            ZoneRuleType.rule(ruleField.value);

    final name = ZoneRuleName.parse(nameField);
    if (name == null) return null;

    if (type is! RuleZoneRuleType &&
        name is FormattedWithVariableZoneRuleName) {
      nameField.logError('“%s” used in a zone without an associated rule');
      return null;
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

      final TimeWithReference untilTime;
      if (untilTimeField == null) {
        untilTime = (const Seconds(0), TimeReference.localTime);
      } else {
        final time = RuleClause.parseTime(untilTimeField);
        if (time == null) return null;
        untilTime = time;
      }

      untilEpochTime = calculateRuleClauseEpochTime(
        untilMonth,
        untilDayCode,
        untilTime.$1,
        untilYear,
      );
    }

    final rule = ZoneRule(
      standardOffset: standardOffset,
      type: type,
      name: name,
    );

    return (rule, untilEpochTime);
  }

  final String name;
  // TODO: Can/should ends be a local `DateTime` instead?
  final List<(ZoneRule, Seconds)> rulesWithEnd;
  final ZoneRule lastRule;
  Iterable<ZoneRule> get allRules =>
      rulesWithEnd.map((it) => it.$1).followedBy([lastRule]);

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

@freezed
sealed class ZoneRule with _$ZoneRule {
  const factory ZoneRule({
    /// Local standard time
    required SecondsDuration standardOffset,
    required ZoneRuleType type,
    required ZoneRuleName name,
  }) = _ZoneRule;
  const ZoneRule._();

  @override
  String toString() {
    final typeString = switch (type) {
      RuleZoneRuleType(:final ruleName) =>
        'Standard offset $standardOffset and rule $ruleName',
      OffsetZoneRuleType(:final offset) =>
        'Standard offset $standardOffset plus offset $offset',
      NoneZoneRuleType() => 'Standard offset $standardOffset',
    };
    return '$name: $typeString';
  }
}

@freezed
sealed class ZoneRuleName with _$ZoneRuleName {
  /// A name with defined strings for standard and DST time.
  ///
  /// E.g., `BMT/BST` becomes
  /// `ZoneRuleName.either(standard: 'BMT', dst: 'CST')`.
  const factory ZoneRuleName.either({
    required String standard,
    required String dst,
  }) = EitherZoneRuleName;

  /// A formatted name into which [RuleClause.abbreviationVariable] gets
  /// inserted.
  ///
  /// E.g., `CE%sT` becomes `ZoneRuleName.formatted('CE', 'T')`.
  const factory ZoneRuleName.formattedWithVariable(String start, String end) =
      FormattedWithVariableZoneRuleName;

  /// A name that shows the formatted offset.
  const factory ZoneRuleName.formattedOffset() = FormattedOffsetZoneRuleName;

  const factory ZoneRuleName.simple(String value) = SimpleZoneRuleName;

  const ZoneRuleName._();

  /// Original: `inzsub`, `doabbr`
  static ZoneRuleName? parse(Field field) {
    final percentIndex = field.value.indexOfOrNull('%');
    final slashIndex = field.value.indexOfOrNull('/');
    if (percentIndex != null) {
      if (percentIndex == field.value.length - 1 ||
          slashIndex != null ||
          field.value.substring(percentIndex + 1).contains('%')) {
        field.logError('Invalid abbreviation format');
        return null;
      }

      switch (field.value[percentIndex + 1]) {
        case 's':
          return ZoneRuleName.formattedWithVariable(
            field.value.substring(0, percentIndex),
            field.value.substring(percentIndex + 2),
          );
        case 'z':
          return const ZoneRuleName.formattedOffset();
        default:
          field.logError('Invalid abbreviation format');
          return null;
      }
    }
    if (slashIndex != null) {
      return ZoneRuleName.either(
        standard: field.value.substring(0, slashIndex),
        dst: field.value.substring(slashIndex + 1),
      );
    }
    return ZoneRuleName.simple(field.value);
  }

  @override
  String toString() {
    return switch (this) {
      EitherZoneRuleName(:final standard, :final dst) => '$standard/$dst',
      FormattedWithVariableZoneRuleName(:final start, :final end) =>
        '$start%s$end',
      FormattedOffsetZoneRuleName() => '%z',
      SimpleZoneRuleName(:final value) => value,
    };
  }
}

@freezed
sealed class ZoneRuleType with _$ZoneRuleType {
  /// Local time is [ZoneRule.standardOffset] + the named rule.
  const factory ZoneRuleType.rule(String ruleName) = RuleZoneRuleType;

  /// Local time is [ZoneRule.standardOffset] + [offset].
  const factory ZoneRuleType.offset(SecondsDuration offset) =
      OffsetZoneRuleType;

  /// Local time is to [ZoneRule.standardOffset].
  const factory ZoneRuleType.none() = NoneZoneRuleType;

  const ZoneRuleType._();
}
