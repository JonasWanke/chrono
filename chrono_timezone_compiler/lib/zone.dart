import 'package:chrono/chrono.dart';
import 'package:oxidized/oxidized.dart';
import 'package:supernova/supernova.dart';

import 'field.dart';
import 'line.dart';
import 'rule.dart';
import 'utils.dart';
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
  static ParseResult<(String, ZoneRule, ZoneRuleEnd?)> parse(Line line) {
    final fields = line.fields.toList();
    fields.first.require('Zone');
    if (fields.length < 5 || fields.length > 9) {
      return Err(ParseException.line(
        line,
        'Wrong number of fields on zone line',
      ));
    }

    // TODO: Handle `-l localtime` argument
    // TODO: Handle `-p posixrules` argument

    if (!fields.second.isValidName()) {
      return Err(ParseException(fields.second, 'Not a valid name'));
    }

    final result = _parseHelper(fields.sublist(2));
    if (result.isErr()) {
      return result.asErrorWithContext('Invalid initial zone line');
    }
    final (ruleName, ruleEnd) = result.unwrap();

    return Ok((fields.second.value, ruleName, ruleEnd));
  }

  /// Original: `inzcont`
  static ParseResult<(ZoneRule, ZoneRuleEnd?)> parseContinuation(Line line) {
    if (line.fields.length < 3 || line.fields.length > 7) {
      return Err(ParseException.line(
        line,
        'Wrong number of fields on zone continuation line',
      ));
    }

    return _parseHelper(line.fields.toList());
  }

  /// Original: `inzsub`
  static ParseResult<(ZoneRule, ZoneRuleEnd?)> _parseHelper(
    List<Field> fields,
  ) {
    final standardOffsetField = fields.first;
    final ruleField = fields[1];
    final nameField = fields[2];

    final standardOffsetResult = standardOffsetField.parseHms();
    if (standardOffsetResult.isErr()) {
      return standardOffsetResult.asErrorWithContext('Invalid UT offset');
    }
    final standardOffset = standardOffsetResult.unwrap();

    // In the original, the last for loop of `associate` checks if a rule with
    // the name of [ruleField.value] exists. If not, the string is parsed using
    // `getsave` and stored as `z_save` and `z_isdst`.
    //
    // To simplify the code structure, we first try parsing the string as an
    // offset and assume it's a rule if that fails.
    final type = ruleField.value.isEmpty
        ? const ZoneRuleType.none()
        : RuleClause.parseOffsetAndDst(ruleField)
            .map((it) => ZoneRuleType.offset(it.$1, isDst: it.isDst))
            .unwrapOrElse((_) => ZoneRuleType.rule(ruleField.value));

    final nameResult = ZoneRuleName.parse(nameField);
    if (nameResult.isErr()) {
      return nameResult.asErrorWithContext('Invalid name for zone line');
    }
    final name = nameResult.unwrap();

    if (type is! RuleZoneRuleType &&
        name is FormattedWithVariableZoneRuleName) {
      return Err(ParseException(
        nameField,
        '“%s” used in a zone without an associated rule',
      ));
    }

    ZoneRuleEnd? until;
    if (fields.length > 3) {
      final untilYearField = fields[3];
      final untilMonthField = fields.elementAtOrNull(4);
      final untilDayField = fields.elementAtOrNull(5);
      final untilTimeField = fields.elementAtOrNull(6);

      // TODO: Simplify this to a `Year`?
      final untilYearResult = RuleClause.parseStartYear(untilYearField);
      if (untilYearResult.isErr()) {
        return untilYearResult
            .asErrorWithContext('Invalid until year in zone line');
      }
      final untilYear = untilYearResult.unwrap();

      final Month untilMonth;
      if (untilMonthField == null) {
        untilMonth = Month.january;
      } else {
        final monthResult = untilMonthField.parseMonth();
        if (monthResult.isErr()) {
          return monthResult.asErrorWithContext('Invalid month in zone line');
        }
        untilMonth = monthResult.unwrap();
      }

      final DayCode untilDayCode;
      if (untilDayField == null) {
        untilDayCode = const DayCode.dayOfMonth(1);
      } else {
        final dayCodeResult = DayCode.parse(untilDayField, untilMonth);
        if (dayCodeResult.isErr()) {
          return dayCodeResult
              .asErrorWithContext('Invalid day code in zone line');
        }
        untilDayCode = dayCodeResult.unwrap();
      }

      final TimeWithReference untilTime;
      if (untilTimeField == null) {
        untilTime = (const Seconds(0), TimeReference.localTime);
      } else {
        final timeResult = RuleClause.parseTime(untilTimeField);
        if (timeResult.isErr()) {
          return timeResult.asErrorWithContext('Invalid time in zone line');
        }
        untilTime = timeResult.unwrap();
      }

      final dateTime = calculateRuleClauseDateTime(
        untilMonth,
        untilDayCode,
        untilTime.$1,
        untilYear,
      );
      until = ZoneRuleEnd(dateTime, untilTime.$2);
    }

    final rule = ZoneRule(
      standardOffset: standardOffset,
      type: type,
      name: name,
    );

    return Ok((rule, until));
  }

  final String name;
  final List<(ZoneRule, ZoneRuleEnd)> rulesWithEnd;
  final ZoneRule lastRule;
  Iterable<(ZoneRule, ZoneRuleEnd?)> get allRules => rulesWithEnd
      .cast<(ZoneRule, ZoneRuleEnd?)>()
      .followedBy([(lastRule, null)]);

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

/// Original: `zone`
@freezed
sealed class ZoneRule with _$ZoneRule {
  const factory ZoneRule({
    /// Local standard time
    ///
    /// Original: `z_stdoff`
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
      OffsetZoneRuleType(:final offset, :final isDst) =>
        'Standard offset $standardOffset with offset $offset and isDst = $isDst',
      NoneZoneRuleType() => 'Standard offset $standardOffset',
    };
    return '$name: $typeString';
  }
}

@freezed
sealed class ZoneRuleEnd with _$ZoneRuleEnd {
  // TODO(JonasWanke): Use `LimitOr<DateTime>`?
  const factory ZoneRuleEnd(CDateTime dateTime, TimeReference timeReference) =
      _ZoneRuleEnd;
}

/// Original: `z_format`, `z_format_specifier`
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
  static ParseResult<ZoneRuleName> parse(Field field) {
    final percentIndex = field.value.indexOfOrNull('%');
    final slashIndex = field.value.indexOfOrNull('/');
    if (percentIndex != null) {
      if (percentIndex == field.value.length - 1 ||
          slashIndex != null ||
          field.value.substring(percentIndex + 1).contains('%')) {
        return Err(ParseException(field, 'Invalid abbreviation format'));
      }

      switch (field.value[percentIndex + 1]) {
        case 's':
          return Ok(ZoneRuleName.formattedWithVariable(
            field.value.substring(0, percentIndex),
            field.value.substring(percentIndex + 2),
          ));
        case 'z':
          return const Ok(ZoneRuleName.formattedOffset());
        default:
          return Err(ParseException(field, 'Invalid abbreviation format'));
      }
    }
    if (slashIndex != null) {
      return Ok(ZoneRuleName.either(
        standard: field.value.substring(0, slashIndex),
        dst: field.value.substring(slashIndex + 1),
      ));
    }
    return Ok(ZoneRuleName.simple(field.value));
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
  // TODO(JonasWanke): Store rules here instead of a name
  const factory ZoneRuleType.rule(
    /// Original: `zone.z_rule`
    String ruleName,
  ) = RuleZoneRuleType;

  /// Local time is [ZoneRule.standardOffset] + [offset].
  const factory ZoneRuleType.offset(
    /// Original: `zone.z_save`
    // TODO(JonasWanke): Change to `Seconds`
    SecondsDuration offset, {
    /// Original: `zone.z_isdst`
    required bool isDst,
  }) = OffsetZoneRuleType;

  /// Local time is to [ZoneRule.standardOffset].
  const factory ZoneRuleType.none() = NoneZoneRuleType;

  const ZoneRuleType._();
}
