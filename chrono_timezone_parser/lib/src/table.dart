import 'package:chrono/chrono.dart';

import '../chrono_timezone_parser.dart';

/// A **table** of all the data in one or more zoneinfo files.
class Table {
  Table({required this.rulesets, required this.zonesets, required this.links});

  /// Mapping of ruleset names to rulesets.
  final Map<String, List<TableRuleInfo>> rulesets;

  /// Mapping of zoneset names to zonesets.
  final Map<String, List<TableZoneInfo>> zonesets;

  /// Mapping of link timezone names to the names they link to.
  final Map<String, String> links;

  /// Tries to find the zoneset with the given name by looking it up in either
  /// [zonesets] or [links].
  List<TableZoneInfo>? getZoneset(String zoneName) =>
      zonesets[zoneName] ?? zonesets[links[zoneName]];
}

/// A builder for [Table] values based on various line definitions.
class TableBuilder {
  /// The table that’s being built up.
  final _table = Table(rulesets: {}, zonesets: {}, links: {});

  /// If the last line was a zone definition, then this holds its name.
  /// `None` otherwise. This is so continuation lines can be added to the
  /// same zone as the original zone line.
  String? _currentZonesetName;

  void add(Line line) {
    switch (line) {
      case Space():
        // Ignore space lines.
        break;
      case final Zone zone:
        addZoneLine(zone);
      case final ZoneContinuation zoneContinuation:
        addContinuationLine(zoneContinuation.info);
      case final Rule rule:
        addRuleLine(rule);
      case final Link link:
        addLinkLine(link);
    }
  }

  /// Adds a new line describing a zone definition.
  ///
  /// Returns an error if there’s already a zone with the same name, or the
  /// zone refers to a ruleset that hasn’t been defined yet.
  void addZoneLine(Zone zoneLine) {
    if (zoneLine.info.saving case Saving_Multiple(:final name)) {
      if (!_table.rulesets.containsKey(name)) {
        throw TableBuildException.unknownRuleset(name);
      }
    }

    if (_table.zonesets.containsKey(zoneLine.name)) {
      throw TableBuildException.duplicateZone(zoneLine.name);
    }
    _table.zonesets[zoneLine.name] = [TableZoneInfo.from(zoneLine.info)];
    _currentZonesetName = zoneLine.name;
  }

  /// Adds a new line describing the *continuation* of a zone definition.
  ///
  /// Returns an error if the builder wasn’t expecting a continuation line
  /// (meaning, the previous line wasn’t a zone line)
  void addContinuationLine(ZoneInfo continuationLine) {
    final zoneset = _table.zonesets[_currentZonesetName];
    if (zoneset == null) {
      throw TableBuildException.surpriseContinuationLine();
    }

    zoneset.add(TableZoneInfo.from(continuationLine));
  }

  /// Adds a new line describing one entry in a ruleset, creating that set
  /// if it didn’t exist already.
  void addRuleLine(Rule ruleLine) {
    final ruleset = _table.rulesets.putIfAbsent(ruleLine.name, () => []);

    ruleset.add(TableRuleInfo.from(ruleLine));
    _currentZonesetName = null;
  }

  /// Adds a new line linking one zone to another.
  ///
  /// Returns an error if there was already a link with that name.
  void addLinkLine(Link linkLine) {
    if (_table.links.containsKey(linkLine.newName)) {
      throw TableBuildException.duplicateLink(linkLine.newName);
    }

    _table.links[linkLine.newName] = linkLine.existingName;
    _currentZonesetName = null;
  }

  /// Returns the table after it’s finished being built.
  Table build() => _table;
}

/// Something that can go wrong while constructing a [Table].
class TableBuildException extends FormatException {
  /// A continuation line was passed in, but the previous line wasn’t a zone
  /// definition line.
  TableBuildException.surpriseContinuationLine()
    : super(
        "Continuation line follows line that isn't a zone definition line.",
      );

  /// A zone definition referred to a ruleset that hadn’t been defined.
  TableBuildException.unknownRuleset(String name)
    : super(
        'Zone definition refers to a ruleset that isn\'t defined: "$name".',
      );

  /// A link line was passed in, but there’s already a link with that name.
  TableBuildException.duplicateLink(String name)
    : super('Link line with name that already exists: "$name".');

  /// A zone line was passed in, but there’s already a zone with that name.
  TableBuildException.duplicateZone(String name)
    : super('Zone line with name that already exists: "$name".');
}

/// A rule definition line.
///
/// This mimics the [Rule] class, but has had some pre-processing applied to it.
class TableRuleInfo {
  const TableRuleInfo({
    required this.fromYear,
    required this.toYear,
    required this.month,
    required this.day,
    required this.time,
    required this.timeType,
    required this.timeToAdd,
    required this.letters,
  });

  factory TableRuleInfo.from(Rule info) {
    return TableRuleInfo(
      fromYear: info.fromYear,
      toYear: info.toYear,
      month: info.month,
      day: info.day,
      time: info.time.timeSpec.asSeconds(),
      timeType: info.time.timeType,
      timeToAdd: info.timeToAdd.asSeconds(),
      letters: info.letters,
    );
  }

  /// The year that this rule *starts* applying.
  final YearSpec fromYear;

  /// The year that this rule *finishes* applying, inclusive, or `None` if it
  /// applies up until the end of this timespan.
  final YearSpec? toYear;

  /// The month it applies on.
  final Month month;

  /// The day it applies on.
  final DaySpec day;

  /// The exact time it applies on.
  final int time;

  /// The type of time that time is.
  final TimeType timeType;

  /// The amount of time to save.
  final int timeToAdd;

  /// Any extra letters that should be added to this time zone’s abbreviation,
  /// in place of `%s`.
  final String? letters;

  /// Returns whether this rule is in effect during the given year.
  bool appliesToYear(Year year) {
    return switch ((fromYear, toYear)) {
      (YearSpec_Number(year: final from), null) => year == from,
      (YearSpec_Number(year: final from), YearSpec_Maximum _) => year >= from,
      (YearSpec_Number(year: final from), YearSpec_Number(year: final to)) =>
        year >= from && year <= to,
      _ => throw Exception('Unreachable'),
    };
  }

  int absoluteDateTime(Year year, int utcOffset, int dstOffset) {
    final offset = switch (timeType) {
      TimeType.utc => 0,
      TimeType.standard => utcOffset,
      TimeType.wall => utcOffset + dstOffset,
    };

    final changetime = ChangeTime_UntilDay(YearSpec_Number(year), month, day);
    return changetime.toTimestamp() + time - offset;
  }
}

/// An owned zone definition line.
///
/// This mimics the [ZoneInfo] class, *not* the [Zone] class, which is the key
/// name in the map – this is just the value.
class TableZoneInfo {
  const TableZoneInfo({
    required this.offset,
    required this.saving,
    required this.format,
    required this.endTime,
  });

  factory TableZoneInfo.from(ZoneInfo info) {
    return TableZoneInfo(
      offset: info.utcOffset.asSeconds(),
      saving: info.saving,
      format: Format(info.format),
      endTime: info.time,
    );
  }

  /// The number of seconds that need to be added to UTC to get the standard
  /// time in this zone.
  final int offset;

  /// The name of all the rules that should apply in the time zone, or the
  /// amount of daylight-saving time to add.
  final Saving saving;

  /// The format for time zone abbreviations.
  final Format format;

  /// The time at which the rules change for this time zone, or `None` if these
  /// rules are in effect until the end of time (!).
  final ChangeTime? endTime;
}

// Format

/// The format string to generate a time zone abbreviation from.
sealed class Format {
  /// Convert the template into one of the `Format` variants. This can’t fail,
  /// as any syntax that doesn’t match one of the two formats will just be a
  /// [Format_Constant].
  factory Format(String template) {
    final slashIndex = template.indexOf('/');
    if (slashIndex >= 0) {
      return Format_Alternative(
        standard: template.substring(0, slashIndex),
        dst: template.substring(slashIndex + 1),
      );
    } else if (template.contains('%s')) {
      return Format_Placeholder(template);
    } else {
      return Format_Constant(template);
    }
  }
  const Format._();

  String format(int dstOffset, String? letters);
}

/// A constant format, which remains the same throughout both standard and DST
/// timespans.
// ignore: camel_case_types
class Format_Constant extends Format {
  const Format_Constant(this.value) : super._();

  final String value;

  @override
  String format(int dstOffset, String? letters) => value;
}

/// An alternate format, such as “PST/PDT”, which changes between standard and
/// DST timespans.
// ignore: camel_case_types
class Format_Alternative extends Format {
  const Format_Alternative({required this.standard, required this.dst})
    : super._();

  /// Abbreviation to use during Standard Time.
  final String standard;

  /// Abbreviation to use during Summer Time.
  final String dst;

  @override
  String format(int dstOffset, String? letters) =>
      dstOffset == 0 ? standard : dst;
}

/// A format with a placeholder `%s`, which uses [TableRuleInfo.letters] to
/// generate the time zone abbreviation.
// ignore: camel_case_types
class Format_Placeholder extends Format {
  const Format_Placeholder(this.pattern) : super._();

  final String pattern;

  @override
  String format(int dstOffset, String? letters) =>
      pattern.replaceAll('%s', letters ?? '');
}
