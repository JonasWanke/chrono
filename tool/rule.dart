import 'package:chrono/chrono.dart';
import 'package:supernova/supernova.dart' hide Weekday;

import 'field.dart';
import 'line.dart';
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
    required this.isStd,
    required this.isUt,
    required this.isDst,
    required this.offset,
    required this.abbreviationVariable,
  });

  /// Original: `inrule`
  static (String, RuleClause)? parse(Line line) {
    line.fields.first.require('Rule');
    if (line.fields.length != 10) {
      line.logError('Wrong number of fields on rule line');
      return null;
    }

    final nameField = line.fields.second;
    switch (nameField.value) {
      case '\x00' || ' ' || '\f' || '\n' || '\r' || '\t' || '\v' || '+' || '-':
      case '0' || '1' || '2' || '3' || '4' || '5' || '6' || '7' || '8' || '9':
        nameField.throwFormatException('Invalid rule name');
    }

    final offsetAndDst = _parseOffsetAndDst(line.fields[8]);
    if (offsetAndDst == null) return null;

    final subFields = RuleClause._parseSubfields(
      startYearField: line.fields[2],
      endYearField: line.fields[3],
      yearTypeField: line.fields[4],
      monthField: line.fields[5],
      dayField: line.fields[6],
      timeField: line.fields[7],
    );
    if (subFields == null) return null;

    final clause = RuleClause(
      startYear: subFields.startYear,
      endYear: subFields.endYear,
      month: subFields.month,
      dayCode: subFields.dayCode,
      time: subFields.time.time,
      isStd: subFields.time.isStd,
      isUt: subFields.time.isUt,
      isDst: offsetAndDst.isDst,
      offset: offsetAndDst.$1,
      abbreviationVariable: line.fields[9].value,
    );
    return (nameField.value, clause);
  }

  /// Original: `getsave`
  static (SecondsDuration, {bool isDst})? _parseOffsetAndDst(Field field) {
    final isDst = switch (field.value[field.value.length - 1]) {
      'd' => true,
      's' => false,
      _ => null,
    };

    final save = field.parseHms(
      end: isDst == null ? field.value.length : field.value.length - 1,
      errorText: 'Invalid saved time',
    );
    if (save == null) return null;

    return (save, isDst: isDst ?? save != const Seconds(0));
  }

  static final _startYearLookup =
      ['minimum', 'maximum'].associateWith((it) => it);
  static final _endYearLookup =
      ['minimum', 'maximum', 'only'].associateWith((it) => it);

  /// Original: `rulesub`
  static ({
    RuleYear startYear,
    RuleYear endYear,
    Month month,
    DayCode dayCode,
    TimeWithZoneInfo time,
  })? _parseSubfields({
    required Field startYearField,
    required Field endYearField,
    required Field yearTypeField,
    required Field monthField,
    required Field dayField,
    required Field timeField,
  }) {
    final month = monthField.parseMonth();
    if (month == null) return null;

    final time = parseTime(timeField);
    if (time == null) return null;

    // Years
    final startYear = parseStartYear(startYearField);
    if (startYear == null) return null;

    final endYear = switch (endYearField.getByWord(_endYearLookup)) {
      'minimum' => const RuleYear.min(),
      'maximum' => const RuleYear.max(),
      'only' => startYear,
      _ => RuleYear(Year(
          int.tryParse(endYearField.value) ??
              endYearField.throwFormatException('Invalid end year'),
        )),
    };

    switch ((startYear, endYear)) {
      case (_RuleYear(), _MinRuleYear()) ||
            (_MaxRuleYear(), _MinRuleYear() || _RuleYear()):
      case (_RuleYear(year: final startYear), _RuleYear(year: final endYear))
          when startYear > endYear:
        endYearField.throwFormatException(
          'Invalid year range: “$startYearField – $endYearField”',
        );
      default:
    }
    if (yearTypeField.value.isNotEmpty) {
      yearTypeField.throwFormatException('Invalid year type, use “-” instead.');
    }

    final dayCode = DayCode.parse(dayField, month);
    if (dayCode == null) return null;

    return (
      startYear: startYear,
      endYear: endYear,
      month: month,
      dayCode: dayCode,
      time: time,
    );
  }

  static RuleYear? parseStartYear(Field yearField) {
    switch (yearField.getByWord(_startYearLookup)) {
      case 'minimum':
        return const RuleYear.min();
      case 'maximum':
        return const RuleYear.max();
      default:
        final value = int.tryParse(yearField.value);
        if (value != null) return RuleYear(Year(value));

        yearField.logError('Invalid starting year');
        return null;
    }
  }

  static TimeWithZoneInfo? parseTime(Field timeField) {
    // TODO: Convert to an enum `standard`, `wall`, `utc`?
    final timeString = timeField.value;
    var isStd = false;
    var isUt = false;
    var end = timeString.length;
    if (timeString.isNotEmpty) {
      switch (timeString[timeString.length - 1].toLowerCase()) {
        case 's': // Standard
          isStd = true;
          isUt = false;
          end = timeString.length - 1;
          break;
        case 'w': // Wall
          isStd = false;
          isUt = false;
          end = timeString.length - 1;
          break;
        case 'g': // Greenwich
        case 'u': // Universal
        case 'z': // Zulu
          isStd = true;
          isUt = true;
          end = timeString.length - 1;
          break;
      }
    }

    final time = timeField.parseHms(end: end, errorText: 'Invalid time of day');
    if (time == null) return null;

    return (time: time, isStd: isStd, isUt: isUt);
  }

  final RuleYear startYear;
  final RuleYear endYear;

  final Month month;

  final DayCode dayCode;

  /// Time of day
  ///
  /// Can exceed the range of [Time], e.g., be equal to 24 hours.
  final SecondsDuration time;
  final bool isStd;
  final bool isUt;
  final bool isDst;
  final SecondsDuration offset;
  final String abbreviationVariable;

  @override
  String toString() {
    final yearRange = switch ((startYear, endYear)) {
      (_RuleYear(year: final startYear), _RuleYear(year: final endYear))
          when startYear == endYear =>
        startYear.toString(),
      _ => '$startYear – $endYear',
    };
    return '$yearRange on $month $dayCode at $time '
        '${isUt ? 'UTC' : isStd ? 'standard time' : 'wall time'}: '
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
  RuleYear targetRuleYear,
) {
  final Year targetYear;
  switch (targetRuleYear) {
    case _MinRuleYear():
      return minTime;
    case _MaxRuleYear():
      return maxTime;
    case _RuleYear(year: final year):
      targetYear = year;
  }

  // TODO: Confirm that this is correct
  final yearMonth = YearMonth(targetYear, ruleClauseMonth);
  Date date;
  switch (ruleClauseDayCode) {
    case _DayOfMonthDayCode(day: final day):
      if (yearMonth.month == Month.february &&
          day == 29 &&
          !yearMonth.year.isLeapYear) {
        throw ArgumentError('Use of February 29 in non-leap-year');
      }
      date = Date.fromYearMonthAndDay(yearMonth, day).unwrap();
    case _LessThanOrEqualToDayCode(weekday: final weekday, day: final day):
      date = Date.fromYearMonthAndDay(yearMonth, day).unwrap();
      date = date.previousOrSame(weekday);
    case _GreaterThanOrEqualToDayCode(weekday: final weekday, day: final day):
      date = Date.fromYearMonthAndDay(yearMonth, day).unwrap();
      date = date.nextOrSame(weekday);
  }
  return (date.at(Time.midnight) + ruleClauseTime)
      .durationSinceUnixEpoch
      .roundToSeconds();
}

typedef TimeWithZoneInfo = ({SecondsDuration time, bool isStd, bool isUt});

@freezed
sealed class RuleYear with _$RuleYear {
  const factory RuleYear(Year year) = _RuleYear;
  const factory RuleYear.min() = _MinRuleYear;
  const factory RuleYear.max() = _MaxRuleYear;
  const RuleYear._();

  @override
  String toString() {
    return switch (this) {
      _RuleYear(:final year) => year.toString(),
      _MinRuleYear() => 'min',
      _MaxRuleYear() => 'max',
    };
  }
}

@freezed
sealed class DayCode with _$DayCode {
  const factory DayCode.dayOfMonth(int day) = _DayOfMonthDayCode;
  const factory DayCode.lessThanOrEqualTo(Weekday weekday, int day) =
      _LessThanOrEqualToDayCode;
  const factory DayCode.greaterThanOrEqualTo(Weekday weekday, int day) =
      _GreaterThanOrEqualToDayCode;
  const DayCode._();

  /// Accept things such as:
  ///
  /// - `1`
  /// - `lastSunday`
  /// - `last-Sunday` (undocumented)
  /// - `Sun<=20`
  /// - `Sun>=7`
  static DayCode? parse(Field field, Month month) {
    final lastWeekday = field.getByWord(_lastLookupWithoutHyphen) ??
        field.getByWord(_lastLookupWithHyphen);
    if (lastWeekday != null) {
      return DayCode.lessThanOrEqualTo(lastWeekday, month.maxLastDay.day);
    }

    final lessThanIndex = field.value.indexOfOrNull('<=');
    final greaterThanIndex =
        lessThanIndex != null ? null : field.value.indexOfOrNull('>=');
    final index = lessThanIndex ?? greaterThanIndex;
    if (index != null) {
      final weekday = field.parseWeekday(0, index);
      if (weekday == null) return null;

      final dayString = field.value.substring(index + 2);
      final day = int.tryParse(dayString);
      if (day == null) {
        field.logError('Invalid day of month');
        return null;
      }

      return lessThanIndex != null
          ? DayCode.lessThanOrEqualTo(weekday, day)
          : DayCode.greaterThanOrEqualTo(weekday, day);
    }

    final day = int.tryParse(field.value);
    if (day == null) {
      field.logError('Invalid day of month');
      return null;
    }
    return DayCode.dayOfMonth(day);
  }

  static final _lastLookupWithoutHyphen =
      Weekday.values.associate((it) => MapEntry('last$it', it));
  static final _lastLookupWithHyphen =
      Weekday.values.associate((it) => MapEntry('last-$it', it));

  @override
  String toString() {
    return switch (this) {
      _DayOfMonthDayCode(:final day) => day.toString(),
      _LessThanOrEqualToDayCode(weekday: final weekday, day: final day) =>
        '$weekday<=$day',
      _GreaterThanOrEqualToDayCode(weekday: final weekday, day: final day) =>
        '$weekday>=$day',
    };
  }
}
