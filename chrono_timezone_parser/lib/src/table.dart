import 'package:chrono/chrono.dart';

import '../chrono_timezone_parser.dart';

/// A **table** of all the data in one or more zoneinfo files.
class Table {
  const Table({
    required this.rulesets,
    required this.zonesets,
    this.links = const {},
  });

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

  /// Computes a fixed timespan set for the timezone with the given name.
  ///
  /// Returns `null` if the table doesn’t contain a time zone with that name.
  FixedTimespanSet? timespans(String zoneName) {
    final zoneset = getZoneset(zoneName);
    if (zoneset == null) return null;

    final builder = FixedTimespanSetBuilder();
    for (final (i, zoneInfo) in zoneset.indexed) {
      var dstOffsetSeconds = 0;
      final useUntil = i != zoneset.length - 1;
      final utcOffsetSeconds = zoneInfo.offsetSeconds;

      var insertStartTransition = i > 0;
      String? startZoneId;
      var startUtcOffset = zoneInfo.offsetSeconds;
      var startDstOffset = 0;

      switch (zoneInfo.saving) {
        case Saving_None():
          startZoneId = builder.addFixedSaving(
            zoneInfo,
            utcOffsetSeconds: utcOffsetSeconds,
            dstOffsetSeconds: 0,
            insertStartTransition: insertStartTransition,
          );
          dstOffsetSeconds = 0;
          insertStartTransition = false;

        case Saving_OneOff(:final timeSpec):
          dstOffsetSeconds = timeSpec.asSeconds();
          startZoneId = builder.addFixedSaving(
            zoneInfo,
            utcOffsetSeconds: utcOffsetSeconds,
            dstOffsetSeconds: dstOffsetSeconds,
            insertStartTransition: insertStartTransition,
          );
          insertStartTransition = false;

        case Saving_Multiple(:final name):
          final result = builder.addMultipleSaving(
            zoneInfo,
            rulesets[name]!,
            dstOffsetSeconds: dstOffsetSeconds,
            useUntil: useUntil,
            utcOffsetSeconds: utcOffsetSeconds,
            insertStartTransition: insertStartTransition,
            startZoneId: startZoneId,
            startUtcOffset: startUtcOffset,
            startDstOffset: startDstOffset,
          );
          dstOffsetSeconds = result.dstOffsetSeconds;
          startZoneId = result.startZoneId;
          startUtcOffset = result.startUtcOffset;
          startDstOffset = result.startDstOffset;
      }

      if (insertStartTransition && startZoneId != null) {
        builder.rest.add((
          builder.startTime!,
          FixedTimespan(
            startZoneId,
            utcOffsetSeconds: startUtcOffset,
            dstOffsetSeconds: startDstOffset,
          ),
        ));
      }

      if (useUntil) {
        builder.startTime = zoneInfo.endTime!.toTimestamp(
          utcOffsetSeconds,
          dstOffsetSeconds,
        );
      }
    }

    return builder.build();
  }
}

/// A builder for [Table] values based on various line definitions.
class TableBuilder {
  /// The table that’s being built up.
  final _rulesets = <String, List<TableRuleInfo>>{};
  final _zonesets = <String, List<TableZoneInfo>>{};
  final _links = <String, String>{};

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
      if (!_rulesets.containsKey(name)) {
        throw TableBuildException.unknownRuleset(name);
      }
    }

    if (_zonesets.containsKey(zoneLine.name)) {
      throw TableBuildException.duplicateZone(zoneLine.name);
    }
    _zonesets[zoneLine.name] = [TableZoneInfo.from(zoneLine.info)];
    _currentZonesetName = zoneLine.name;
  }

  /// Adds a new line describing the *continuation* of a zone definition.
  ///
  /// Returns an error if the builder wasn’t expecting a continuation line
  /// (meaning, the previous line wasn’t a zone line)
  void addContinuationLine(ZoneInfo continuationLine) {
    final zoneset = _zonesets[_currentZonesetName];
    if (zoneset == null) {
      throw TableBuildException.surpriseContinuationLine();
    }

    zoneset.add(TableZoneInfo.from(continuationLine));
  }

  /// Adds a new line describing one entry in a ruleset, creating that set
  /// if it didn’t exist already.
  void addRuleLine(Rule ruleLine) {
    final ruleset = _rulesets.putIfAbsent(ruleLine.name, () => []);

    ruleset.add(TableRuleInfo.from(ruleLine));
    _currentZonesetName = null;
  }

  /// Adds a new line linking one zone to another.
  ///
  /// Returns an error if there was already a link with that name.
  void addLinkLine(Link linkLine) {
    if (_links.containsKey(linkLine.newName)) {
      throw TableBuildException.duplicateLink(linkLine.newName);
    }

    _links[linkLine.newName] = linkLine.existingName;
    _currentZonesetName = null;
  }

  /// Returns the table after it’s finished being built.
  Table build() =>
      Table(rulesets: _rulesets, zonesets: _zonesets, links: _links);
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

  int absoluteDateTime(Year year, int utcOffsetSeconds, int dstOffsetSeconds) {
    final offsetSeconds = switch (timeType) {
      TimeType.utc => 0,
      TimeType.standard => utcOffsetSeconds,
      TimeType.wall => utcOffsetSeconds + dstOffsetSeconds,
    };

    final changetime = ChangeTime_UntilDay(YearSpec_Number(year), month, day);
    return changetime.toTimestamp(0, 0) + time - offsetSeconds;
  }
}

/// An owned zone definition line.
///
/// This mimics the [ZoneInfo] class, *not* the [Zone] class, which is the key
/// name in the map – this is just the value.
class TableZoneInfo {
  const TableZoneInfo({
    required this.offsetSeconds,
    required this.saving,
    required this.format,
    required this.endTime,
  });

  factory TableZoneInfo.from(ZoneInfo info) {
    return TableZoneInfo(
      offsetSeconds: info.utcOffset.asSeconds(),
      saving: info.saving,
      format: Format(info.format),
      endTime: info.time,
    );
  }

  /// The number of seconds that need to be added to UTC to get the standard
  /// time in this zone.
  final int offsetSeconds;

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
    } else if (template.contains('%z')) {
      return const Format_Offset();
    } else {
      return Format_Constant(template);
    }
  }
  const Format._();

  String format(int utcOffsetSeconds, int dstOffsetSeconds, String? letters);
}

/// A constant format, which remains the same throughout both standard and DST
/// timespans.
// ignore: camel_case_types
class Format_Constant extends Format {
  const Format_Constant(this.value) : super._();

  final String value;

  @override
  String format(int utcOffsetSeconds, int dstOffsetSeconds, String? letters) =>
      value;
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
  String format(int utcOffsetSeconds, int dstOffsetSeconds, String? letters) =>
      dstOffsetSeconds == 0 ? standard : dst;
}

/// A format with a placeholder `%s`, which uses [TableRuleInfo.letters] to
/// generate the time zone abbreviation.
// ignore: camel_case_types
class Format_Placeholder extends Format {
  const Format_Placeholder(this.pattern) : super._();

  final String pattern;

  @override
  String format(int utcOffsetSeconds, int dstOffsetSeconds, String? letters) =>
      pattern.replaceAll('%s', letters ?? '');
}

/// The special `%z` placeholder that gets formatted as a numeric offset.
// ignore: camel_case_types
class Format_Offset extends Format {
  const Format_Offset() : super._();

  @override
  String format(int utcOffsetSeconds, int dstOffsetSeconds, String? letters) {
    final offsetSeconds = utcOffsetSeconds + dstOffsetSeconds;
    final (sign, offset) = offsetSeconds < 0
        ? ('-', -offsetSeconds)
        : ('+', offsetSeconds);

    final minutesRaw = offset ~/ TimeDelta.secondsPerMinute;
    final seconds = offset % TimeDelta.secondsPerMinute;
    final minutes = minutesRaw % TimeDelta.minutesPerHour;
    final hours = minutesRaw ~/ TimeDelta.minutesPerHour;
    assert(
      seconds == 0,
      'Numeric names are not used if the offset has fractional minutes.',
    );

    String format(int number) => number.toString().padLeft(2, '0');
    return minutes == 0
        ? '$sign${format(hours)}'
        : '$sign${format(hours)}:${format(minutes)}';
  }
}
