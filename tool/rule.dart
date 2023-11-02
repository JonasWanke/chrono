import 'package:chrono/chrono.dart';
import 'package:oxidized/oxidized.dart';
import 'package:supernova/supernova.dart' hide Weekday;

import 'field.dart';
import 'line.dart';
import 'utils.dart';
import 'zone_information_compiler.dart';

part 'rule.freezed.dart';

@immutable
final class Rule {
  const Rule({required this.name, required this.clauses});

  final String name;
  final List<RuleClause> clauses;

  @override
  String toString() => 'Rule $name:${clauses.map((it) => '\n• $it').join()}';
}

@immutable
final class RuleClause {
  const RuleClause({
    required this.startYear,
    required this.endYear,
    required this.month,
    required this.dayCode,
    required this.time,
    required this.timeReference,
    required this.isDst,
    required this.offset,
    required this.abbreviationVariable,
  });

  /// Original: `inrule`
  static ParseResult<(String, RuleClause)> parse(Line line) {
    final fields = line.fields.toList();
    fields.first.require('Rule');
    if (fields.length != 10) {
      return Err(ParseException.line(
        line,
        'Wrong number of fields on rule line',
      ));
    }

    final nameField = fields.second;
    switch (nameField.value) {
      case '\x00' || ' ' || '\f' || '\n' || '\r' || '\t' || '\v' || '+' || '-':
      case '0' || '1' || '2' || '3' || '4' || '5' || '6' || '7' || '8' || '9':
        nameField.throwFormatException('Invalid rule name');
    }

    final offsetAndDstResult = parseOffsetAndDst(fields[8]);
    if (offsetAndDstResult.isErr()) {
      return offsetAndDstResult
          .asErrorWithContext('Invalid offset or DST in rule line');
    }
    final offsetAndDst = offsetAndDstResult.unwrap();

    final subFieldsResult = RuleClause._parseSubfields(
      startYearField: fields[2],
      endYearField: fields[3],
      yearTypeField: fields[4],
      monthField: fields[5],
      dayField: fields[6],
      timeField: fields[7],
    );
    if (subFieldsResult.isErr()) {
      return subFieldsResult
          .asErrorWithContext('Invalid subfields in rule line');
    }
    final subFields = subFieldsResult.unwrap();

    final clause = RuleClause(
      startYear: subFields.startYear,
      endYear: subFields.endYear,
      month: subFields.month,
      dayCode: subFields.dayCode,
      time: subFields.time.$1,
      timeReference: subFields.time.$2,
      isDst: offsetAndDst.isDst,
      offset: offsetAndDst.$1,
      abbreviationVariable: fields[9].value.emptyToNull,
    );
    return Ok((nameField.value, clause));
  }

  /// Original: `getsave`
  static ParseResult<(SecondsDuration, {bool isDst})> parseOffsetAndDst(
    Field field,
  ) {
    final isDst = switch (field.value[field.value.length - 1]) {
      'd' => true,
      's' => false,
      _ => null,
    };

    final save = field.parseHms(
      end: isDst == null ? field.value.length : field.value.length - 1,
    );
    if (save.isErr()) return save.asErrorWithContext('Invalid saved time');

    return Ok((
      save.unwrap(),
      isDst: isDst ?? save.unwrap() != const Seconds(0),
    ));
  }

  static final _startYearLookup =
      ['minimum', 'maximum'].associateWith((it) => it);
  static final _endYearLookup =
      ['minimum', 'maximum', 'only'].associateWith((it) => it);

  /// Original: `rulesub`
  static ParseResult<
      ({
        LimitOr<Year> startYear,
        LimitOr<Year> endYear,
        Month month,
        DayCode dayCode,
        TimeWithReference time,
      })> _parseSubfields({
    required Field startYearField,
    required Field endYearField,
    required Field yearTypeField,
    required Field monthField,
    required Field dayField,
    required Field timeField,
  }) {
    final monthResult = monthField.parseMonth();
    if (monthResult.isErr()) {
      return monthResult.asErrorWithContext('Invalid month in rule subfields');
    }
    final month = monthResult.unwrap();

    final timeResult = parseTime(timeField);
    if (timeResult.isErr()) {
      return timeResult.asErrorWithContext('Invalid time in rule subfields');
    }
    final time = timeResult.unwrap();

    // Years
    final startYearResult = parseStartYear(startYearField);
    if (startYearResult.isErr()) {
      return startYearResult
          .asErrorWithContext('Invalid start year in zone line');
    }
    final startYear = startYearResult.unwrap();

    final endYear = switch (endYearField.getByWord(_endYearLookup)) {
      'minimum' => const LimitOrMin<Year>(),
      'maximum' => const LimitOrMax<Year>(),
      'only' => startYear,
      _ => LimitOrValue(Year(
          int.tryParse(endYearField.value) ??
              endYearField.throwFormatException('Invalid end year'),
        )),
    };

    switch ((startYear, endYear)) {
      case (LimitOrValue(), LimitOrMin()) ||
            (LimitOrMax(), LimitOrMin() || LimitOrValue()):
      case (
            LimitOrValue(value: final startYear),
            LimitOrValue(value: final endYear),
          )
          when startYear > endYear:
        endYearField.throwFormatException(
          'Invalid year range: “$startYearField – $endYearField”',
        );
      default:
    }
    if (yearTypeField.value.isNotEmpty) {
      yearTypeField.throwFormatException('Invalid year type, use “-” instead.');
    }

    final dayCodeResult = DayCode.parse(dayField, month);
    if (dayCodeResult.isErr()) {
      return dayCodeResult
          .asErrorWithContext('Invalid day code in rule subfields');
    }
    final dayCode = dayCodeResult.unwrap();

    return Ok((
      startYear: startYear,
      endYear: endYear,
      month: month,
      dayCode: dayCode,
      time: time,
    ));
  }

  static ParseResult<LimitOr<Year>> parseStartYear(Field yearField) {
    switch (yearField.getByWord(_startYearLookup)) {
      case 'minimum':
        return const Ok(LimitOrMin());
      case 'maximum':
        return const Ok(LimitOrMax());
      default:
        final value = int.tryParse(yearField.value);
        if (value != null) return Ok(LimitOrValue(Year(value)));

        return Err(ParseException(yearField, 'Invalid starting year'));
    }
  }

  static ParseResult<TimeWithReference> parseTime(Field timeField) {
    final timeString = timeField.value;
    var reference = TimeReference.localTime;
    var end = timeString.length;
    if (timeString.isNotEmpty) {
      switch (timeString[timeString.length - 1].toLowerCase()) {
        case 's': // Standard
          reference = TimeReference.localStandardTime;
          end = timeString.length - 1;
          break;
        case 'w': // Wall
          reference = TimeReference.localTime;
          end = timeString.length - 1;
          break;
        case 'g': // Greenwich
        case 'u': // Universal
        case 'z': // Zulu
          reference = TimeReference.universalTime;
          end = timeString.length - 1;
          break;
      }
    }

    final time = timeField.parseHms(end: end);
    if (time.isErr()) return time.asErrorWithContext('Invalid time of day');

    return Ok((time.unwrap(), reference));
  }

  /// Original: `r_loyear`, `r_lowasnum`
  final LimitOr<Year> startYear;

  /// Original: `r_hiyear`, `r_hiwasnum`
  final LimitOr<Year> endYear;

  /// Original: `r_month`
  final Month month;

  /// Original: `r_dycode`, `r_dayofmonth`, `r_wday`
  final DayCode dayCode;

  /// Time of day
  ///
  /// Can exceed the range of [Time], e.g., be equal to 24 hours.
  ///
  /// Original: `r_tod`
  final SecondsDuration time;

  /// Original: `r_todisstd`, `r_todisut`
  final TimeReference timeReference;

  /// Original: `r_isdst`
  final bool isDst;

  /// Original: `r_save`
  final SecondsDuration offset; // TODO(JonasWanke): Change to `Seconds`
  /// Original: `r_abbrvar`
  final String? abbreviationVariable;

  // `r_todo` and `r_temp` are only used when writing zones to TZif files, so
  // they are represented there.

  @override
  String toString() {
    final yearRange = switch ((startYear, endYear)) {
      (
        LimitOrValue(value: final startYear),
        LimitOrValue(value: final endYear),
      )
          when startYear == endYear =>
        startYear.toString(),
      _ => '$startYear – $endYear',
    };
    final timeReferenceString = switch (timeReference) {
      TimeReference.localTime => 'local time',
      TimeReference.localStandardTime => 'local standard time',
      TimeReference.universalTime => 'universal time',
    };
    return '$yearRange on $month $dayCode at $time $timeReferenceString: '
        'offset = $offset, abbreviation variable = “$abbreviationVariable”';
  }
}

/// Given rule clause information and a year, compute the date (in seconds since
/// January 1, 1970, 00:00 LOCAL time) in that year that the rule clause refers
/// to.
///
/// Original: `rpytime`
Seconds calculateRuleClauseEpochTime(
  Month ruleClauseMonth,
  DayCode ruleClauseDayCode,
  SecondsDuration ruleClauseTime,
  LimitOr<Year> targetRuleYear,
) {
  return calculateRuleClauseDateTime(
    ruleClauseMonth,
    ruleClauseDayCode,
    ruleClauseTime,
    targetRuleYear,
  ).durationSinceUnixEpoch.roundToSeconds();
}

/// Given rule clause information and a year, compute the date (in seconds since
/// January 1, 1970, 00:00 LOCAL time) in that year that the rule clause refers
/// to.
///
/// Original: `rpytime`
// TODO(JonasWanke): Return `UnixEpochSeconds`
DateTime calculateRuleClauseDateTime(
  Month ruleClauseMonth,
  DayCode ruleClauseDayCode,
  SecondsDuration ruleClauseTime,
  LimitOr<Year> targetRuleYear,
) {
  final Year targetYear;
  switch (targetRuleYear) {
    case LimitOrMin():
      return minDateTime;
    case LimitOrValue(:final value):
      targetYear = value;
    case LimitOrMax():
      return maxDateTime;
  }

  // TODO: Confirm that this is correct
  final yearMonth = YearMonth(targetYear, ruleClauseMonth);
  Date date;
  switch (ruleClauseDayCode) {
    case DayOfMonthDayCode(day: final day):
      if (yearMonth.month == Month.february &&
          day == 29 &&
          !yearMonth.year.isLeapYear) {
        throw ArgumentError('Use of February 29 in non-leap-year');
      }
      date = Date.fromYearMonthAndDay(yearMonth, day).unwrap();
    case LessThanOrEqualToDayCode(weekday: final weekday, day: final day):
      date = Date.fromYearMonthAndDay(yearMonth, day).unwrap();
      date = date.previousOrSame(weekday);
    case GreaterThanOrEqualToDayCode(weekday: final weekday, day: final day):
      date = Date.fromYearMonthAndDay(yearMonth, day).unwrap();
      date = date.nextOrSame(weekday);
  }
  return date.at(Time.midnight) + ruleClauseTime;
}

typedef TimeWithReference = (SecondsDuration, TimeReference);

// @freezed
// sealed class RuleYear with _$RuleYear {
//   const factory RuleYear(Year year) = LiteralRuleYear;
//   const factory RuleYear.min() = MinRuleYear;
//   const factory RuleYear.max() = MaxRuleYear;
//   const RuleYear._();

//   @override
//   String toString() {
//     return switch (this) {
//       LiteralRuleYear(:final year) => year.toString(),
//       MinRuleYear() => 'min',
//       MaxRuleYear() => 'max',
//     };
//   }
// }

@freezed
sealed class DayCode with _$DayCode {
  /// Original: `rule` with `r_dycode = DC_DOM`
  const factory DayCode.dayOfMonth(
    /// Original: `r_dayofmonth`
    int day,
  ) = DayOfMonthDayCode;

  /// Original: `rule` with `r_dycode = DC_DOWLEQ`
  const factory DayCode.lessThanOrEqualTo(
    /// Original: `r_wday`
    Weekday weekday,

    /// Original: `r_dayofmonth`
    int day,
  ) = LessThanOrEqualToDayCode;

  /// Original: `rule` with `r_dycode = DC_DOWGEQ`
  const factory DayCode.greaterThanOrEqualTo(
    /// Original: `r_wday`
    Weekday weekday,

    /// Original: `r_dayofmonth`
    int day,
  ) = GreaterThanOrEqualToDayCode;
  const DayCode._();

  /// Accept things such as:
  ///
  /// - `1`
  /// - `lastSunday`
  /// - `last-Sunday` (undocumented)
  /// - `Sun<=20`
  /// - `Sun>=7`
  static ParseResult<DayCode> parse(Field field, Month month) {
    final lastWeekday = field.getByWord(_lastLookupWithoutHyphen) ??
        field.getByWord(_lastLookupWithHyphen);
    if (lastWeekday != null) {
      return Ok(DayCode.lessThanOrEqualTo(lastWeekday, month.maxLastDay.day));
    }

    final lessThanIndex = field.value.indexOfOrNull('<=');
    final greaterThanIndex =
        lessThanIndex != null ? null : field.value.indexOfOrNull('>=');
    final index = lessThanIndex ?? greaterThanIndex;
    if (index != null) {
      final weekdayResult = field.parseWeekday(0, index);
      if (weekdayResult.isErr()) {
        return weekdayResult.asErrorWithContext('Invalid weekday in day code');
      }
      final weekday = weekdayResult.unwrap();

      final dayString = field.value.substring(index + 2);
      final day = int.tryParse(dayString);
      if (day == null) {
        return Err(ParseException(field, 'Invalid day of month $month'));
      }

      return Ok(
        lessThanIndex != null
            ? DayCode.lessThanOrEqualTo(weekday, day)
            : DayCode.greaterThanOrEqualTo(weekday, day),
      );
    }

    final day = int.tryParse(field.value);
    if (day == null) {
      return Err(ParseException(field, 'Invalid day of month $month'));
    }
    return Ok(DayCode.dayOfMonth(day));
  }

  static final _lastLookupWithoutHyphen =
      Weekday.values.associate((it) => MapEntry('last$it', it));
  static final _lastLookupWithHyphen =
      Weekday.values.associate((it) => MapEntry('last-$it', it));

  @override
  String toString() {
    return switch (this) {
      DayOfMonthDayCode(:final day) => day.toString(),
      LessThanOrEqualToDayCode(weekday: final weekday, day: final day) =>
        '$weekday<=$day',
      GreaterThanOrEqualToDayCode(weekday: final weekday, day: final day) =>
        '$weekday>=$day',
    };
  }
}

enum TimeReference {
  /// The local (wall clock) time.
  localTime(isStd: false, isUt: false),

  /// The local standard time.
  ///
  /// This differs from [localTime] when observing daylight saving time.
  localStandardTime(isStd: true, isUt: false),

  /// UT or UTC, whichever was official at the time.
  universalTime(isStd: true, isUt: true);

  const TimeReference({required this.isStd, required this.isUt});

  final bool isStd;
  final bool isUt;

  static TimeReference from({required bool isStd, required bool isUt}) =>
      values.firstWhere((it) => it.isStd == isStd && it.isUt == isUt);

  Seconds getAdjustment(SecondsDuration standardOffset, SecondsDuration save) {
    var result = const Seconds(0);
    if (!isStd) result += save;
    if (!isUt) result += standardOffset;
    return result;
  }
}
