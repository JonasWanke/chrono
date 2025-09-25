import 'package:chrono/chrono.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

abstract final class LineParser {
  static final _ruleLine = RegExp(
    '^'
    r'Rule\s+'
    r'(?<name>\S+)\s+'
    r'(?<from>\S+)\s+'
    r'(?<to>\S+)\s+'
    r'(?<type>\S+)\s+'
    r'(?<in>\S+)\s+'
    r'(?<on>\S+)\s+'
    r'(?<at>\S+)\s+'
    r'(?<save>\S+)\s+'
    r'(?<letters>\S+)\s*'
    '(#.*)?'
    r'$',
  );
  static final _dayField = RegExp(
    '^'
    r'(?<weekday>\w+)'
    '(?<sign>[<>]=)'
    r'(?<day>\d+)'
    r'$',
  );
  static final _hmField = RegExp(
    '^'
    '(?<sign>-?)'
    r'(?<hour>\d{1,2}):(?<minute>\d{2})'
    '(?<flag>[wsugz])?'
    r'$',
  );
  static final _hmsField = RegExp(
    '^'
    '(?<sign>-?)'
    r'(?<hour>\d{1,2}):(?<minute>\d{2}):(?<second>\d{2})'
    '(?<flag>[wsugz])?'
    r'$',
  );
  static final _zoneLine = RegExp(
    '^'
    r'Zone\s+'
    r'(?<name>[A-Za-z0-9/_+-]+)\s+'
    r'(?<gmtoff>\S+)\s+'
    r'(?<rulessave>\S+)\s+'
    r'(?<format>\S+)\s*'
    r'(?<year>[0-9]+)?\s*'
    r'(?<month>[A-Za-z]+)?\s*'
    r'(?<day>[A-Za-z0-9><=]+)?\s*'
    r'(?<time>[0-9:]+[suwz]?)?\s*'
    '(#.*)?'
    r'$',
  );
  static final _continuationLine = RegExp(
    '^'
    r'\s+'
    r'(?<gmtoff>\S+)\s+'
    r'(?<rulessave>\S+)\s+'
    r'(?<format>\S+)\s*'
    r'(?<year>[0-9]+)?\s*'
    r'(?<month>[A-Za-z]+)?\s*'
    r'(?<day>[A-Za-z0-9><=]+)?\s*'
    r'(?<time>[0-9:]+[suwz]?)?\s*'
    '(#.*)?'
    r'$',
  );
  static final _linkLine = RegExp(
    '^'
    r'Link\s+'
    r'(?<target>\S+)\s+'
    r'(?<name>\S+)\s*'
    '(#.*)?'
    r'$',
  );
  static final _emptyLine = RegExp(
    '^'
    r'\s*'
    '(#.*)?'
    r'$',
  );

  /// Attempt to parse this line, returning a `Line` depending on what
  /// type of line it was, or an `Error` if it couldn't be parsed.
  static Result<Line, LineParserException> parse(String input) {
    if (_emptyLine.hasMatch(input)) return const Ok(Space());

    if (parseZone(input) case final result?) return result;
    if (_continuationLine.firstMatch(input) case final value?) {
      return _zoneInfoFromCaptures(value).map(ZoneContinuation.new);
    }
    if (_parseRule(input) case final result?) return result;
    if (_parseLink(input) case final result?) return result;
    return Err(LineParserException.invalidLineType(input));
  }

  static Result<Rule, LineParserException>? _parseRule(String input) {
    final match = _ruleLine.firstMatch(input);
    if (match == null) return null;

    final name = match.namedGroup('name')!;

    final YearSpec fromYear;
    switch (YearSpec.parse(match.namedGroup('from')!)) {
      case Ok(:final value):
        fromYear = value;
      case Err(:final error):
        return Err(error);
    }

    // The end year can be ‘only’ to indicate that this rule only
    // takes place on that year.
    final toYearRaw = match.namedGroup('to')!;
    final YearSpec? toYear;
    if (toYearRaw == 'only') {
      toYear = null;
    } else {
      switch (YearSpec.parse(toYearRaw)) {
        case Ok(:final value):
          toYear = value;
        case Err(:final error):
          return Err(error);
      }
    }

    // According to the spec, the only value inside the ‘type’ column should
    // be “-”, so throw an LineParserException if it isn’t. (It only exists
    // for compatibility with old versions that used to contain year types.)
    // Sometimes “‐”, a Unicode hyphen, is used as well.
    final t = match.namedGroup('type')!;
    if (t != '-' && t != '\u{2010}') {
      return Err(LineParserException.typeColumnContainedNonHyphen(t));
    }

    final Month month;
    switch (MonthExtension.parse(match.namedGroup('in')!)) {
      case Ok(:final value):
        month = value;
      case Err(:final error):
        return Err(error);
    }
    final DaySpec day;
    switch (_parseDaySpec(match.namedGroup('on')!)) {
      case Ok(:final value):
        day = value;
      case Err(:final error):
        return Err(error);
    }
    final TimeSpecAndType time;
    switch (_parseTimeSpecAndType(match.namedGroup('at')!)) {
      case Ok(:final value):
        time = value;
      case Err(:final error):
        return Err(error);
    }
    final TimeSpec timeToAdd;
    switch (_parseTimeSpec(match.namedGroup('save')!)) {
      case Ok(:final value):
        timeToAdd = value;
      case Err(:final error):
        return Err(error);
    }
    final letters = switch (match.namedGroup('letters')) {
      '-' => null,
      final l => l,
    };

    return Ok(
      Rule(
        name,
        fromYear: fromYear,
        toYear: toYear,
        month: month,
        day: day,
        time: time,
        timeToAdd: timeToAdd,
        letters: letters,
      ),
    );
  }

  @visibleForTesting
  static Result<Zone, LineParserException>? parseZone(String input) {
    final match = _zoneLine.firstMatch(input);
    if (match == null) return null;

    final name = match.namedGroup('name')!;
    return _zoneInfoFromCaptures(match).map((info) => Zone(name, info));
  }

  static Result<ZoneInfo, LineParserException> _zoneInfoFromCaptures(
    RegExpMatch match,
  ) {
    final TimeSpec utcOffset;
    switch (_parseTimeSpec(match.namedGroup('gmtoff')!)) {
      case Ok(:final value):
        utcOffset = value;
      case Err(:final error):
        return Err(error);
    }
    final Saving saving;
    switch (_parseSaving(match.namedGroup('rulessave')!)) {
      case Ok(:final value):
        saving = value;
      case Err(:final error):
        return Err(error);
    }
    final format = match.namedGroup('format')!;

    // The year, month, day, and time fields are all optional, meaning
    // that it should be impossible to, say, have a defined month but not
    // a defined year.
    final ChangeTime? time;
    switch (_parseChangeTime(
      match.namedGroup('year'),
      match.namedGroup('month'),
      match.namedGroup('day'),
      match.namedGroup('time'),
    )) {
      case Ok(:final value):
        time = value;
      case Err(:final error):
        return Err(error);
    }

    return Ok(
      ZoneInfo(
        utcOffset: utcOffset,
        saving: saving,
        format: format,
        time: time,
      ),
    );
  }

  static Result<Saving, LineParserException> _parseSaving(String input) {
    if (input == '-') {
      return const Ok(Saving_None());
    }
    if (RegExp(r'^[-_A-Za-z]+$').hasMatch(input)) {
      return Ok(Saving_Multiple(input));
    }
    if (_hmField.hasMatch(input)) {
      return _parseTimeSpec(input).map(Saving_OneOff.new);
    } else {
      return Err(LineParserException.couldNotParseSaving(input));
    }
  }

  static Result<ChangeTime?, LineParserException> _parseChangeTime(
    String? year,
    String? month,
    String? day,
    String? time,
  ) {
    switch ((year, month, day, time)) {
      case (final rawYear?, final rawMonth?, final rawDay?, final rawTime?):
        final YearSpec year;
        switch (YearSpec.parse(rawYear)) {
          case Ok(:final value):
            year = value;
          case Err(:final error):
            return Err(error);
        }
        final Month month;
        switch (MonthExtension.parse(rawMonth)) {
          case Ok(:final value):
            month = value;
          case Err(:final error):
            return Err(error);
        }
        final DaySpec day;
        switch (_parseDaySpec(rawDay)) {
          case Ok(:final value):
            day = value;
          case Err(:final error):
            return Err(error);
        }
        final TimeSpecAndType time;
        switch (_parseTimeSpecAndType(rawTime)) {
          case Ok(:final value):
            time = value;
          case Err(:final error):
            return Err(error);
        }
        return Ok(ChangeTime_UntilTime(year, month, day, time));

      case (final rawYear?, final rawMonth?, final rawDay?, null):
        final YearSpec year;
        switch (YearSpec.parse(rawYear)) {
          case Ok(:final value):
            year = value;
          case Err(:final error):
            return Err(error);
        }
        final Month month;
        switch (MonthExtension.parse(rawMonth)) {
          case Ok(:final value):
            month = value;
          case Err(:final error):
            return Err(error);
        }
        final DaySpec day;
        switch (_parseDaySpec(rawDay)) {
          case Ok(:final value):
            day = value;
          case Err(:final error):
            return Err(error);
        }
        return Ok(ChangeTime_UntilDay(year, month, day));

      case (final rawYear?, final rawMonth?, null, null):
        final YearSpec year;
        switch (YearSpec.parse(rawYear)) {
          case Ok(:final value):
            year = value;
          case Err(:final error):
            return Err(error);
        }
        final Month month;
        switch (MonthExtension.parse(rawMonth)) {
          case Ok(:final value):
            month = value;
          case Err(:final error):
            return Err(error);
        }
        return Ok(ChangeTime_UntilMonth(year, month));

      case (final rawYear?, null, null, null):
        return YearSpec.parse(rawYear).map(ChangeTime_UntilYear.new);

      case (null, null, null, null):
        return const Ok(null);

      default:
        throw Exception('Out-of-order capturing groups!');
    }
  }

  static Result<DaySpec, LineParserException> _parseDaySpec(String input) {
    // Parse the field as a number if it vaguely resembles one.
    if (int.tryParse(input) case final number?) {
      return Ok(DaySpec_Ordinal(number));
    }
    // Check if it stars with ‘last’, and trim off the first four bytes if
    // it does. (Luckily, the file is ASCII, so ‘last’ is four bytes)
    else if (input.startsWith('last')) {
      return switch (WeekdayExtension.parse(input.substring(4))) {
        Ok(:final value) => Ok(DaySpec_Last(value)),
        Err(:final error) => Err(error),
      };
    }
    // Check if it’s a relative expression with the regex.
    else if (_dayField.firstMatch(input) case final match?) {
      final weekday = WeekdayExtension.parse(
        match.namedGroup('weekday')!,
      ).unwrap();
      final day = int.parse(match.namedGroup('day')!);

      return switch (match.namedGroup('sign')) {
        '<=' => Ok(DaySpec_LastOnOrBefore(weekday, day)),
        '>=' => Ok(DaySpec_FirstOnOrAfter(weekday, day)),
        _ => throw Exception('The regex only matches one of those two!'),
      };
    }
    // Otherwise, give up.
    else {
      return Err(LineParserException.invalidDaySpec(input));
    }
  }

  static Result<TimeSpec, LineParserException> _parseTimeSpec(String input) {
    return switch (_parseTimeSpecAndType(input)) {
      Ok(value: TimeSpecAndType(:final timeSpec, timeType: TimeType.wall)) =>
        Ok(timeSpec),
      Ok(value: TimeSpecAndType _) => Err(
        LineParserException.nonWallClockInTimeSpec(input),
      ),
      Err(:final error) => Err(error),
    };
  }

  static Result<TimeSpecAndType, LineParserException> _parseTimeSpecAndType(
    String input,
  ) {
    if (input == '-') {
      return const Ok(TimeSpecAndType(TimeSpec_Zero(), TimeType.wall));
    } else if (int.tryParse(input) case final hours?) {
      return Ok(TimeSpecAndType(TimeSpec_Hours(hours), TimeType.wall));
    } else if (_hmField.firstMatch(input) case final match?) {
      final sign = (match.namedGroup('sign')! == '-') ? -1 : 1;
      final hour = int.parse(match.namedGroup('hour')!);
      final minute = int.parse(match.namedGroup('minute')!);
      final flag =
          match
              .namedGroup('flag')
              .let((it) => TimeType.parse(it.substring(0, 1))) ??
          TimeType.wall;

      return Ok(
        TimeSpecAndType(
          TimeSpec_HoursMinutes(hour * sign, minute * sign),
          flag,
        ),
      );
    } else if (_hmsField.firstMatch(input) case final match?) {
      final sign = (match.namedGroup('sign')! == '-') ? -1 : 1;
      final hour = int.parse(match.namedGroup('hour')!);
      final minute = int.parse(match.namedGroup('minute')!);
      final second = int.parse(match.namedGroup('second')!);
      final flag =
          match
              .namedGroup('flag')
              .let((it) => TimeType.parse(it.substring(0, 1))) ??
          TimeType.wall;

      return Ok(
        TimeSpecAndType(
          TimeSpec_HoursMinutesSeconds(
            hour * sign,
            minute * sign,
            second * sign,
          ),
          flag,
        ),
      );
    } else {
      return Err(LineParserException.invalidTimeSpecAndType(input));
    }
  }

  static Result<Link, LineParserException>? _parseLink(String input) {
    final match = _linkLine.firstMatch(input);
    if (match == null) return null;

    return Ok(
      Link(
        existingName: match.namedGroup('target')!,
        newName: match.namedGroup('name')!,
      ),
    );
  }
}

@immutable
sealed class Line {
  const Line();
}

/// This line is empty.
class Space extends Line {
  const Space();

  @override
  bool operator ==(Object other) => other is Space;
  @override
  int get hashCode => 0;
}

/// A **zone** definition line.
///
/// According to the `zic(8)` man page, a zone line has this form, along with
/// an example:
///
/// ```text
/// Zone  NAME                GMTOFF  RULES/SAVE  FORMAT  [UNTILYEAR [MONTH [DAY [TIME]]]]
/// Zone  Australia/Adelaide  9:30    Aus         AC%sT   1971       Oct    31   2:00
/// ```
///
/// The opening `Zone` identifier is ignored, and the last four columns are all
/// optional, with their variants consolidated into a `ChangeTime`.
///
/// The `Rules/Save` column, if it contains a value, *either* contains the name
/// of the rules to use for this zone, *or* contains a one-off period of time to
/// save.
///
/// A continuation rule line contains all the same fields apart from the `Name`
/// column and the opening `Zone` identifier.
class Zone extends Line {
  const Zone(this.name, this.info);

  /// The name of the time zone.
  final String name;

  /// All the other fields of info.
  final ZoneInfo info;

  @override
  bool operator ==(Object other) =>
      other is Zone && other.name == name && other.info == info;
  @override
  int get hashCode => Object.hash(name, info);
}

/// This line contains a **continuation** of a [Zone] definition.
class ZoneContinuation extends Line {
  const ZoneContinuation(this.info);

  /// All the other fields of info.
  final ZoneInfo info;

  @override
  bool operator ==(Object other) =>
      other is ZoneContinuation && other.info == info;
  @override
  int get hashCode => info.hashCode;
}

/// The information contained in both [Zone] lines *and* [ZoneContinuation]
/// lines.
@immutable
class ZoneInfo {
  const ZoneInfo({
    required this.utcOffset,
    required this.saving,
    required this.format,
    required this.time,
  });

  /// The amount of time that needs to be added to UTC to get the standard
  /// time in this zone.
  final TimeSpec utcOffset;

  /// The name of all the rules that should apply in the time zone, or the
  /// amount of time to add.
  final Saving saving;

  /// The format for time zone abbreviations, with `%s` as the string marker.
  final String format;

  /// The time at which the rules change for this location, or `None` if
  /// these rules are in effect until the end of time (!).
  final ChangeTime? time;

  @override
  bool operator ==(Object other) {
    return other is ZoneInfo &&
        other.utcOffset == utcOffset &&
        other.saving == saving &&
        other.format == format &&
        other.time == time;
  }

  @override
  int get hashCode => Object.hash(utcOffset, saving, format, time);
}

// Saving

/// The amount of daylight saving time (DST) to apply to this timespan. This is
/// a special type for a certain field in a zone line, which can hold different
/// types of value.
@immutable
sealed class Saving {
  const Saving();
}

/// Just stick to the base offset.
// ignore: camel_case_types
class Saving_None extends Saving {
  const Saving_None();

  @override
  bool operator ==(Object other) => other is Saving_None;
  @override
  int get hashCode => 0;
}

/// This amount of time should be saved while this timespan is in effect.
///
/// This is the equivalent to there being a single one-off rule with the given
/// amount of time to save.
// ignore: camel_case_types
class Saving_OneOff extends Saving {
  const Saving_OneOff(this.timeSpec);

  final TimeSpec timeSpec;

  @override
  bool operator ==(Object other) =>
      other is Saving_OneOff && other.timeSpec == timeSpec;
  @override
  int get hashCode => timeSpec.hashCode;
}

/// All rules with the given name should apply while this timespan is in effect.
// ignore: camel_case_types
class Saving_Multiple extends Saving {
  const Saving_Multiple(this.name);

  final String name;

  @override
  bool operator ==(Object other) =>
      other is Saving_Multiple && other.name == name;
  @override
  int get hashCode => name.hashCode;
}

// ChangeTime

/// The time at which the rules change for a location.
///
/// This is described with as few units as possible: a change that occurs at
/// the beginning of the year lists only the year, a change that occurs on a
/// particular day has to list the year, month, and day, and one that occurs
/// at a particular second has to list everything.
@immutable
sealed class ChangeTime {
  const ChangeTime();

  /// Convert this change time to an absolute timestamp, as the number of
  /// seconds since the Unix epoch that the change occurs at.
  int toTimestamp(int utcOffsetSeconds, int dstOffsetSeconds) {
    int timeToTimestamp(Date date, int hour, int minute, int second) {
      return date.daysSinceUnixEpoch.inDays * TimeDelta.secondsPerNormalDay +
          hour * TimeDelta.secondsPerHour +
          minute * TimeDelta.secondsPerMinute +
          second;
    }

    return switch (this) {
      ChangeTime_UntilYear(year: YearSpec_Number(:final year)) =>
        timeToTimestamp(year.dates.start, 0, 0, 0) -
            (utcOffsetSeconds + dstOffsetSeconds),
      ChangeTime_UntilMonth(year: YearSpec_Number(:final year), :final month) =>
        timeToTimestamp(YearMonth(year, month).dates.start, 0, 0, 0) -
            (utcOffsetSeconds + dstOffsetSeconds),
      ChangeTime_UntilDay(
        year: YearSpec_Number(:final year),
        :final month,
        :final day,
      ) =>
        timeToTimestamp(day.toConcreteDay(YearMonth(year, month)), 0, 0, 0) -
            (utcOffsetSeconds + dstOffsetSeconds),
      ChangeTime_UntilTime(
        year: YearSpec_Number(:final year),
        :final month,
        :final day,
        :final time,
      ) =>
        () {
          final (hours, minutes, seconds) = switch (time.timeSpec) {
            TimeSpec_Zero _ => (0, 0, 0),
            TimeSpec_Hours(:final hours) => (hours, 0, 0),
            TimeSpec_HoursMinutes(:final hours, :final minutes) => (
              hours,
              minutes,
              0,
            ),
            TimeSpec_HoursMinutesSeconds(
              :final hours,
              :final minutes,
              :final seconds,
            ) =>
              (hours, minutes, seconds),
          };
          return timeToTimestamp(
                day.toConcreteDay(YearMonth(year, month)),
                hours,
                minutes,
                seconds,
              ) -
              switch (time.timeType) {
                TimeType.utc => 0,
                TimeType.standard => utcOffsetSeconds,
                TimeType.wall => utcOffsetSeconds + dstOffsetSeconds,
              };
        }(),
      _ => throw Exception('Cannot convert non-number year spec to timestamp.'),
    };
  }

  Year getYear() {
    return switch (this) {
      ChangeTime_UntilYear(year: YearSpec_Number(:final year)) ||
      ChangeTime_UntilMonth(year: YearSpec_Number(:final year)) ||
      ChangeTime_UntilDay(year: YearSpec_Number(:final year)) ||
      ChangeTime_UntilTime(year: YearSpec_Number(:final year)) => year,
      _ => throw Exception('Cannot get year from non-number year spec.'),
    };
  }
}

/// The earliest point in a particular **year**.
// ignore: camel_case_types
class ChangeTime_UntilYear extends ChangeTime {
  const ChangeTime_UntilYear(this.year);

  final YearSpec year;

  @override
  bool operator ==(Object other) =>
      other is ChangeTime_UntilYear && other.year == year;
  @override
  int get hashCode => year.hashCode;
}

/// The earliest point in a particular **month**.
// ignore: camel_case_types
class ChangeTime_UntilMonth extends ChangeTime {
  const ChangeTime_UntilMonth(this.year, this.month);

  final YearSpec year;
  final Month month;

  @override
  bool operator ==(Object other) {
    return other is ChangeTime_UntilMonth &&
        other.year == year &&
        other.month == month;
  }

  @override
  int get hashCode => Object.hash(year, month);
}

/// The earliest point in a particular **day**.
// ignore: camel_case_types
class ChangeTime_UntilDay extends ChangeTime {
  const ChangeTime_UntilDay(this.year, this.month, this.day);

  final YearSpec year;
  final Month month;
  final DaySpec day;

  @override
  bool operator ==(Object other) {
    return other is ChangeTime_UntilDay &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);
}

/// The earliest point in a particular **hour, minute, or second**.
// ignore: camel_case_types
class ChangeTime_UntilTime extends ChangeTime {
  const ChangeTime_UntilTime(this.year, this.month, this.day, this.time);

  final YearSpec year;
  final Month month;
  final DaySpec day;
  final TimeSpecAndType time;

  @override
  bool operator ==(Object other) {
    return other is ChangeTime_UntilTime &&
        other.year == year &&
        other.month == month &&
        other.day == day &&
        other.time == time;
  }

  @override
  int get hashCode => Object.hash(year, month, day, time);
}

/// A **year** definition field.
///
/// A year has one of the following representations in a file:
///
/// - `min` or `minimum`, the minimum year possible, for when a rule needs to
///   apply up until the first rule with a specific year;
/// - `max` or `maximum`, the maximum year possible, for when a rule needs to
///   apply after the last rule with a specific year;
/// - a year number, referring to a specific year.
@immutable
sealed class YearSpec {
  const YearSpec();

  static Result<YearSpec, LineParserException> parse(String input) {
    return switch (input.toLowerCase()) {
      'min' || 'minimum' => const Ok(YearSpec_Minimum()),
      'max' || 'maximum' => const Ok(YearSpec_Maximum()),
      final year => () {
        final number = int.tryParse(year);
        return number == null
            ? Err<YearSpec_Number, LineParserException>(
                LineParserException.failedYearParse(input),
              )
            : Ok<YearSpec_Number, LineParserException>(
                YearSpec_Number(Year(number)),
              );
      }(),
    };
  }
}

/// The minimum year possible: `min` or `minimum`.
// ignore: camel_case_types
class YearSpec_Minimum extends YearSpec {
  const YearSpec_Minimum();

  @override
  bool operator ==(Object other) => other is YearSpec_Minimum;
  @override
  int get hashCode => 0;
}

/// The maximum year possible: `max` or `maximum`.
// ignore: camel_case_types
class YearSpec_Maximum extends YearSpec {
  const YearSpec_Maximum();

  @override
  bool operator ==(Object other) => other is YearSpec_Maximum;
  @override
  int get hashCode => 0;
}

/// A specific year number.
// ignore: camel_case_types
class YearSpec_Number extends YearSpec {
  const YearSpec_Number(this.year);

  final Year year;

  @override
  bool operator ==(Object other) =>
      other is YearSpec_Number && other.year == year;
  @override
  int get hashCode => year.hashCode;
}

extension MonthExtension on Month {
  static Result<Month, LineParserException> parse(String input) {
    return switch (input.toLowerCase()) {
      'jan' || 'january' => const Ok(Month.january),
      'feb' || 'february' => const Ok(Month.february),
      'mar' || 'march' => const Ok(Month.march),
      'apr' || 'april' => const Ok(Month.april),
      'may' => const Ok(Month.may),
      'jun' || 'june' => const Ok(Month.june),
      'jul' || 'july' => const Ok(Month.july),
      'aug' || 'august' => const Ok(Month.august),
      'sep' || 'september' => const Ok(Month.september),
      'oct' || 'october' => const Ok(Month.october),
      'nov' || 'november' => const Ok(Month.november),
      'dec' || 'december' => const Ok(Month.december),
      _ => Err(LineParserException.failedMonthParse(input)),
    };
  }
}

extension WeekdayExtension on Weekday {
  static Result<Weekday, LineParserException> parse(String input) {
    return switch (input.toLowerCase()) {
      'mon' || 'monday' => const Ok(Weekday.monday),
      'tue' || 'tuesday' => const Ok(Weekday.tuesday),
      'wed' || 'wednesday' => const Ok(Weekday.wednesday),
      'thu' || 'thursday' => const Ok(Weekday.thursday),
      'fri' || 'friday' => const Ok(Weekday.friday),
      'sat' || 'saturday' => const Ok(Weekday.saturday),
      'sun' || 'sunday' => const Ok(Weekday.sunday),
      _ => Err(LineParserException.failedWeekdayParse(input)),
    };
  }
}

// DaySpec

/// A **day** definition field.
///
/// This can be given in either absolute terms (such as “the fifth day of the
/// month”), or relative terms (such as “the last Sunday of the month”, or
/// “the last Friday before or including the 13th”).
///
/// Note that in the last example, it’s allowed for that particular Friday to
/// *be* the 13th in question.
@immutable
sealed class DaySpec {
  const DaySpec();

  /// Converts this day specification to a concrete date, given the year and
  /// month it should occur in.
  Date toConcreteDay(YearMonth yearMonth) {
    return switch (this) {
      DaySpec_Ordinal(:final day) => Date.fromYearMonthAndDay(
        yearMonth,
        day,
      ).unwrap(),
      DaySpec_Last(:final weekday) =>
        yearMonth.dates.endInclusive.previousOrSame(weekday),
      DaySpec_LastOnOrBefore(:final weekday, :final day) =>
        Date.fromYearMonthAndDay(
          yearMonth,
          day,
        ).unwrap().previousOrSame(weekday),
      DaySpec_FirstOnOrAfter(:final weekday, :final day) =>
        Date.fromYearMonthAndDay(yearMonth, day).unwrap().nextOrSame(weekday),
    };
  }
}

/// A specific day of the month, given by its number.
// ignore: camel_case_types
class DaySpec_Ordinal extends DaySpec {
  const DaySpec_Ordinal(this.day);

  final int day;

  @override
  bool operator ==(Object other) =>
      other is DaySpec_Ordinal && other.day == day;
  @override
  int get hashCode => day.hashCode;
}

/// The last day of the month with a specific weekday.
// ignore: camel_case_types
class DaySpec_Last extends DaySpec {
  const DaySpec_Last(this.weekday);

  final Weekday weekday;

  @override
  bool operator ==(Object other) =>
      other is DaySpec_Last && other.weekday == weekday;
  @override
  int get hashCode => weekday.hashCode;
}

/// The **last** day with the given weekday **before** (or including) a
/// day with a specific number.
// ignore: camel_case_types
class DaySpec_LastOnOrBefore extends DaySpec {
  const DaySpec_LastOnOrBefore(this.weekday, this.day);

  final Weekday weekday;
  final int day;

  @override
  bool operator ==(Object other) {
    return other is DaySpec_LastOnOrBefore &&
        other.weekday == weekday &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(weekday, day);
}

/// The **first** day with the given weekday **after** (or including) a
/// day with a specific number.
// ignore: camel_case_types
class DaySpec_FirstOnOrAfter extends DaySpec {
  const DaySpec_FirstOnOrAfter(this.weekday, this.day);

  final Weekday weekday;
  final int day;

  @override
  bool operator ==(Object other) {
    return other is DaySpec_FirstOnOrAfter &&
        other.weekday == weekday &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(weekday, day);
}

// TimeSpec

/// A **time** definition field.
///
/// A time must have an hours component, with optional minutes and seconds
/// components. It can also be negative with a starting ‘-’.
///
/// Hour 0 is midnight at the start of the day, and Hour 24 is midnight at the
/// end of the day.
@immutable
sealed class TimeSpec {
  const TimeSpec();

  TimeSpecAndType withType(TimeType timeType) =>
      TimeSpecAndType(this, timeType);

  /// Returns the number of seconds past midnight that this time spec
  /// represents.
  int asSeconds() {
    return switch (this) {
      TimeSpec_Hours(:final hours) => hours * TimeDelta.secondsPerHour,
      TimeSpec_HoursMinutes(:final hours, :final minutes) =>
        hours * TimeDelta.secondsPerHour + minutes * TimeDelta.secondsPerMinute,
      TimeSpec_HoursMinutesSeconds(
        :final hours,
        :final minutes,
        :final seconds,
      ) =>
        hours * TimeDelta.secondsPerHour +
            minutes * TimeDelta.secondsPerMinute +
            seconds,
      TimeSpec_Zero _ => 0,
    };
  }
}

/// A number of hours.
// ignore: camel_case_types
class TimeSpec_Hours extends TimeSpec {
  const TimeSpec_Hours(this.hours);

  final int hours;

  @override
  bool operator ==(Object other) =>
      other is TimeSpec_Hours && other.hours == hours;
  @override
  int get hashCode => hours.hashCode;
}

/// A number of hours and minutes.
// ignore: camel_case_types
class TimeSpec_HoursMinutes extends TimeSpec {
  const TimeSpec_HoursMinutes(this.hours, this.minutes);

  final int hours;
  final int minutes;

  @override
  bool operator ==(Object other) {
    return other is TimeSpec_HoursMinutes &&
        other.hours == hours &&
        other.minutes == minutes;
  }

  @override
  int get hashCode => Object.hash(hours, minutes);
}

/// A number of hours, minutes, and seconds.
// ignore: camel_case_types
class TimeSpec_HoursMinutesSeconds extends TimeSpec {
  const TimeSpec_HoursMinutesSeconds(this.hours, this.minutes, this.seconds);

  final int hours;
  final int minutes;
  final int seconds;

  @override
  bool operator ==(Object other) {
    return other is TimeSpec_HoursMinutesSeconds &&
        other.hours == hours &&
        other.minutes == minutes &&
        other.seconds == seconds;
  }

  @override
  int get hashCode => Object.hash(hours, minutes, seconds);
}

/// Zero, or midnight at the start of the day.
// ignore: camel_case_types
class TimeSpec_Zero extends TimeSpec {
  const TimeSpec_Zero();

  @override
  bool operator ==(Object other) => other is TimeSpec_Zero;
  @override
  int get hashCode => 0;
}

enum TimeType {
  wall,
  standard,
  utc;

  static TimeType? parse(String input) {
    return switch (input) {
      'w' => wall,
      's' => standard,
      'u' || 'g' || 'z' => utc,
      _ => null,
    };
  }
}

@immutable
class TimeSpecAndType {
  const TimeSpecAndType(this.timeSpec, this.timeType);

  final TimeSpec timeSpec;
  final TimeType timeType;

  @override
  bool operator ==(Object other) {
    return other is TimeSpecAndType &&
        other.timeSpec == timeSpec &&
        other.timeType == timeType;
  }

  @override
  int get hashCode => Object.hash(timeSpec, timeType);
}

/// A **rule** definition line.
///
/// According to the `zic(8)` man page, a rule line has this form, along with
/// an example:
///
/// ```text
/// Rule  NAME  FROM  TO    TYPE  IN   ON       AT    SAVE  LETTER/S
/// Rule  US    1967  1973  ‐     Apr  lastSun  2:00  1:00  D
/// ```
///
/// Apart from the opening `Rule` to specify which kind of line this is, and the
/// `type` column, every column in the line has a field in this struct.
class Rule extends Line {
  const Rule(
    this.name, {
    required this.fromYear,
    required this.toYear,
    required this.month,
    required this.day,
    required this.time,
    required this.timeToAdd,
    this.letters,
  });

  /// The name of the set of rules that this rule is part of.
  final String name;

  /// The first year in which the rule applies.
  final YearSpec fromYear;

  /// The final year, or `null` if’s ‘only’.
  final YearSpec? toYear;

  /// The month in which the rule takes effect.
  final Month month;

  /// The day on which the rule takes effect.
  final DaySpec day;

  /// The time of day at which the rule takes effect.
  final TimeSpecAndType time;

  /// The amount of time to be added when the rule is in effect.
  final TimeSpec timeToAdd;

  /// The variable part of time zone abbreviations to be used when this rule
  /// is in effect, if any.
  final String? letters;

  @override
  bool operator ==(Object other) {
    return other is Rule &&
        other.name == name &&
        other.fromYear == fromYear &&
        other.toYear == toYear &&
        other.month == month &&
        other.day == day &&
        other.time == time &&
        other.timeToAdd == timeToAdd &&
        other.letters == letters;
  }

  @override
  int get hashCode =>
      Object.hash(name, fromYear, toYear, month, day, time, timeToAdd, letters);
}

/// This line contains a **link** definition.
class Link extends Line {
  const Link({required this.existingName, required this.newName});

  final String existingName;
  final String newName;

  @override
  bool operator ==(Object other) {
    return other is Link &&
        other.existingName == existingName &&
        other.newName == newName;
  }

  @override
  int get hashCode => Object.hash(existingName, newName);
}

@immutable
class LineParserException extends FormatException {
  const LineParserException.failedYearParse(String s)
    : super('Failed to parse as a year value: "$s".');
  const LineParserException.failedMonthParse(String s)
    : super('Failed to parse as a month value: "$s".');
  const LineParserException.failedWeekdayParse(String s)
    : super('Failed to parse as a weekday value: "$s".');
  const LineParserException.invalidLineType(String s)
    : super('Line with invalid format: "$s".');
  const LineParserException.typeColumnContainedNonHyphen(String s)
    : super('"type" column is not a hyphen but has the value: "$s".');
  const LineParserException.couldNotParseSaving(String s)
    : super('Failed to parse RULES column: "$s".');
  const LineParserException.invalidDaySpec(String s)
    : super('Invalid day specification (column "ON"): "$s".');
  const LineParserException.invalidTimeSpecAndType(String s)
    : super('Invalid time: "$s".');
  const LineParserException.nonWallClockInTimeSpec(String s)
    : super('Time value not given as wall time: "$s".');

  @override
  bool operator ==(Object other) =>
      other is LineParserException && other.message == message;
  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'LineParserException: $message';
}

extension<T extends Object> on T? {
  R? let<R>(R Function(T) op) {
    final self = this;
    if (self == null) return null;
    return op(self);
  }
}
