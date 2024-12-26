// Based on: https://github.com/eggert/tz/blob/0bb92ae8f46dc05a62a5904103d4cbfa761730b4/zic.c
// File format explanation: https://data.iana.org/time-zones/tz-how-to.html

import 'package:chrono/chrono.dart';
import 'package:chrono/src/utils.dart';
import 'package:supernova/supernova.dart' hide Instant, Weekday;
import 'package:supernova/supernova_io.dart';

import 'line.dart';
import 'rule.dart';
import 'tzif_encoder.dart';
import 'zone.dart';

// TODO: Rename `RuleClause` → `RuleLine`, `ZoneRule` → `ZoneLine`

Future<void> main(List<String> args) async {
  await initSupernova();

  final files = await args.associateWith((it) => File(it).readAsLines()).wait;
  final (rules, zones) = parseZoneInformationFiles(files);
  // logger.info('Parsed all files', {'rules': rules, 'zones': zones});
  logger.info(
    'Parsed all files',
    {'rule count': rules.length, 'zone count': zones.length},
  );

  await encodeTzif(zones.values.first, rules);

  // for (final entry in zones.entries) {
  //   final zone = entry.value;
  //   for (final zoneRule
  //       in zone.rulesWithEnd.map((it) => it.$1).followedBy([zone.lastRule])) {
  //     if (zoneRule.ruleName == null) {
  //       logger.debug('Zone rule for zone ${zone.name} has no name');
  //       continue;
  //     }

  //     if (!rules.containsKey(zoneRule.ruleName)) {
  //       logger.debug(
  //         'Zone rule for zone ${zone.name} references unknown rule '
  //         '${zoneRule.ruleName}',
  //       );
  //       continue;
  //     }
  //   }
  // }
}

// TODO: Support leap files

(Map<String, Rule>, Map<String, Zone>) parseZoneInformationFiles(
  Map<String, List<String>> lines,
) {
  final rules = <String, Rule>{};
  final zones = <String, Zone>{};
  for (final entry in lines.entries) {
    final (newRules, newZones) =
        parseZoneInformationFile(entry.key, entry.value);
    for (final ruleName in newRules.keys) {
      if (rules.containsKey(ruleName)) {
        logger.warning('Rule “$ruleName” appears in multiple files');
      }
    }
    rules.addAll(newRules);
    zones.addAll(newZones);
  }
  return (rules, zones);
}

/// Original: `infile`
(Map<String, Rule>, Map<String, Zone>) parseZoneInformationFile(
  String fileName,
  List<String> lines,
) {
  var lineIndex = 0;
  Line? readNextLine() {
    while (true) {
      if (lineIndex >= lines.length) return null;
      final line = Line.parse(fileName, lineIndex, lines[lineIndex]);
      lineIndex++;
      if (line.fields.isEmpty) continue;
      return line;
    }
  }

  final ruleClauses = <String, List<RuleClause>>{};
  final zoneRules = <String, List<(ZoneRule, ZoneRuleEnd?)>>{};
  while (true) {
    final line = readNextLine();
    if (line == null) break;

    final lineCodeField = line.fields.first;
    final lineCode = lineCodeField.getByWord(ZoneInformationLineCode.lookup);
    if (lineCode == null) {
      line.logError('Unknown line code');
      continue;
    }

    switch (lineCode) {
      case ZoneInformationLineCode.rule:
        final ruleResult = RuleClause.parse(line);
        if (ruleResult.isErr()) {
          logger.error(ruleResult.toString());
          continue;
        }
        final (name, ruleClause) = ruleResult.unwrap();

        (ruleClauses[name] ??= []).add(ruleClause);

      case ZoneInformationLineCode.zone:
        final zoneResult = Zone.parse(line);
        if (zoneResult.isErr()) {
          logger.error(zoneResult.toString());
          continue;
        }
        final (zoneName, rule, ruleEnd) = zoneResult.unwrap();

        if (zoneRules.containsKey(zoneName)) {
          line.logError('Duplicate zone name “$zoneName”');
          continue;
        }

        final currentZoneRules = [(rule, ruleEnd)];
        zoneRules[zoneName] = currentZoneRules;

        var previousLine = line;
        while (currentZoneRules.last.$2 != null) {
          final newLine = readNextLine();
          if (newLine == null) {
            previousLine.logError('Expected zone continuation line not found');
            break;
          }

          final result = Zone.parseContinuation(newLine);
          if (result.isErr()) {
            logger.error(result.toString());
            continue;
          }

          final (rule, ruleEnd) = result.unwrap();
          if (ruleEnd != null &&
              ruleEnd.dateTime > minDateTime &&
              ruleEnd.dateTime < maxDateTime &&
              currentZoneRules.last.$2!.dateTime > minDateTime &&
              currentZoneRules.last.$2!.dateTime < maxDateTime &&
              currentZoneRules.last.$2!.dateTime >= ruleEnd.dateTime) {
            newLine.logError(
              'Zone continuation line end time is not after end time of previous line',
            );
            continue;
          }

          currentZoneRules.add((rule, ruleEnd));
          previousLine = newLine;
        }

      case ZoneInformationLineCode.link:
        // TODO: Support links
        continue;

      case (_, final lineType):
        line.logError('Unknown line type: $lineType');
    }
  }
  final rules =
      ruleClauses.mapValues((it) => Rule(name: it.key, clauses: it.value));
  final zones = zoneRules.mapValues((it) {
    assert(it.value.last.$2 == null, "Zone's last rule shouldn't have an end");
    final zone = Zone(
      name: it.key,
      rulesWithEnd: it.value
          .take(it.value.length - 1)
          .map((it) => (it.$1, it.$2!))
          .toList(),
      lastRule: it.value.last.$1,
    );
    for (final (rule, _) in zone.allRules) {
      if (rule.type case RuleZoneRuleType(:final ruleName)) {
        if (!ruleClauses.containsKey(ruleName)) {
          logger.error(
            '$fileName: Zone ${zone.name} references unknown rule “$ruleName”',
          );
        }
      }
    }
    return zone;
  });
  return (rules, zones);
}

enum ZoneInformationLineCode {
  rule('Rule'),
  zone('Zone'),
  link('Link');

  const ZoneInformationLineCode(this.name);

  static final lookup = values.associate((it) => MapEntry(it.name, it));

  final String name;
}

// TODO: `min_time`, `max_time`
// TODO: Add a `LimitOr<T>` wrapper?
// const minTime = Seconds(-1000000000000);
// const maxTime = Seconds(1000000000000);
final minDateTime = CDateTime(const Year(-10000).firstDay, Time.midnight);
final maxDateTime = CDateTime(const Year(10000).firstDay, Time.midnight);

/// The time specified by the -R option, defaulting to `MIN_TIME`.
// TODO(JonasWanke): Make these configurable, see original `redundant_time_option`
final redundant_time = min_time;

/// The time specified by an “Expires” line, or negative if no such line exists.
///
/// Original: `leapexpires`
// TODO(JonasWanke): Make this nullable
final leapexpires = UnixEpochSeconds(const Seconds(-1));

// TODO(JonasWanke): Check these values
const ZIC_MIN = 1 << 63;
const ZIC_MAX = (1 << 63) - 1;
const ZIC32_MIN = -1 - 0x7fffffff;
const ZIC32_MAX = 0x7fffffff;

/// The minimum value representable in a TZif file.
final min_time = UnixEpochSeconds(const Seconds(ZIC_MIN));

/// The maximum value representable in a TZif file.
final max_time = UnixEpochSeconds(const Seconds(ZIC_MAX));

final minTime32 = UnixEpochSeconds(const Seconds(ZIC32_MIN));
final maxTime32 = UnixEpochSeconds(const Seconds(ZIC32_MAX));

// TODO(JonasWanke): Make these configurable, see original `timerange_option`
final lo_time = min_time;
final hi_time = max_time;

const bloat = Bloat.fat;

/// Whether the TZif output file should be slim, normal, or be fat for backwards
/// compatibility.
// TODO: Re-add where removed?
enum Bloat {
  slim,
  normal,
  fat;

  /// Original: `want_bloat`
  bool get wantsBloat {
    return switch (this) {
      Bloat.slim => false,
      Bloat.normal || Bloat.fat => true,
    };
  }
}

sealed class LimitOr<T extends Comparable<T>>
    with ComparisonOperatorsFromComparable<T>
    implements Comparable<T> {
  const LimitOr();

  LimitOr<R> map<R extends Comparable<R>>(Mapper<T, R> mapper);
}

final class LimitOrMin<T extends Comparable<T>> extends LimitOr<T> {
  const LimitOrMin();

  @override
  LimitOr<R> map<R extends Comparable<R>>(Mapper<T, R> mapper) =>
      const LimitOrMin();

  @override
  int compareTo(T other) => -1;

  @override
  String toString() => 'min';
}

final class LimitOrValue<T extends Comparable<T>> extends LimitOr<T> {
  const LimitOrValue(this.value);

  final T value;

  @override
  LimitOr<R> map<R extends Comparable<R>>(Mapper<T, R> mapper) =>
      LimitOrValue(mapper(value));

  @override
  int compareTo(T other) => value.compareTo(other);

  @override
  String toString() => value.toString();
}

final class LimitOrMax<T extends Comparable<T>> extends LimitOr<T> {
  const LimitOrMax();

  @override
  LimitOr<R> map<R extends Comparable<R>>(Mapper<T, R> mapper) =>
      const LimitOrMax();

  @override
  int compareTo(T other) => 1;

  @override
  String toString() => 'max';
}

extension StringExtension on String {
  int? indexOfOrNull(Pattern pattern) {
    final index = indexOf(pattern);
    return index >= 0 ? index : null;
  }
}

/// https://en.wikipedia.org/wiki/Unix_time
@immutable
final class UnixEpochSeconds
    with ComparisonOperatorsFromComparable<UnixEpochSeconds>
    implements Comparable<UnixEpochSeconds> {
  UnixEpochSeconds(SecondsDuration duration)
      : durationSinceUnixEpoch = duration.asSeconds;

  final Seconds durationSinceUnixEpoch;

  CDateTime get dateTimeInLocalZone =>
      CDateTime.fromCore(asCoreDateTimeInLocalZone);
  CDateTime get dateTimeInUtc => CDateTime.fromCore(asCoreDateTimeInUtc);

  DateTime get asCoreDateTimeInLocalZone => _getDateTime(isUtc: false);
  DateTime get asCoreDateTimeInUtc => _getDateTime(isUtc: true);
  DateTime _getDateTime({required bool isUtc}) {
    return DateTime.fromMicrosecondsSinceEpoch(
      durationSinceUnixEpoch.roundToMicroseconds().inMicroseconds,
      isUtc: isUtc,
    );
  }

  UnixEpochSeconds operator +(SecondsDuration duration) =>
      UnixEpochSeconds(durationSinceUnixEpoch + duration);
  UnixEpochSeconds operator -(SecondsDuration duration) =>
      UnixEpochSeconds(durationSinceUnixEpoch - duration);

  /// Returns `this - other`.
  Seconds difference(UnixEpochSeconds other) =>
      durationSinceUnixEpoch - other.durationSinceUnixEpoch;

  @override
  int compareTo(UnixEpochSeconds other) =>
      durationSinceUnixEpoch.compareTo(other.durationSinceUnixEpoch);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is UnixEpochSeconds &&
            durationSinceUnixEpoch == other.durationSinceUnixEpoch);
  }

  @override
  int get hashCode => durationSinceUnixEpoch.hashCode;

  @override
  String toString() => '${dateTimeInUtc}Z';

  String toJson() => toString();
}
