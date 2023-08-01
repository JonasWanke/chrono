// Based on: https://github.com/eggert/tz/blob/0bb92ae8f46dc05a62a5904103d4cbfa761730b4/zic.c
// File format explanation: https://data.iana.org/time-zones/tz-how-to.html

import 'package:chrono/chrono.dart';
import 'package:supernova/supernova.dart' hide Weekday;
import 'package:supernova/supernova_io.dart';

import 'line.dart';
import 'rule.dart';
import 'zone.dart';

Future<void> main(List<String> args) async {
  await initSupernova();

  final files = await args.associateWith((it) => File(it).readAsLines()).wait;
  final (rules, zones) = parseZoneInformationFiles(files);
  logger.info('Parsed all files', {'rules': rules, 'zones': zones});
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
  final zoneRules = <String, List<(ZoneRule, Seconds?)>>{};
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
        if (ruleResult == null) continue;
        final (name, ruleClause) = ruleResult;

        (ruleClauses[name] ??= []).add(ruleClause);

      case ZoneInformationLineCode.zone:
        final zoneResult = Zone.parse(line);
        if (zoneResult == null) continue;
        final (zoneName, rule, ruleEnd) = zoneResult;

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
          if (result == null) continue;

          final (rule, ruleEnd) = result;
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
    for (final rule in zone.allRules) {
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
const minTime = Seconds(-1000000000000);
const maxTime = Seconds(-1000000000000);

extension StringExtension on String {
  int? indexOfOrNull(String pattern) {
    final index = indexOf(pattern);
    return index >= 0 ? index : null;
  }
}
