// Based on: https://github.com/eggert/tz/blob/0bb92ae8f46dc05a62a5904103d4cbfa761730b4/zic.c

import 'package:chrono/chrono.dart';
import 'package:supernova/supernova.dart' hide Weekday;
import 'package:supernova/supernova_io.dart';

import 'line.dart';
import 'rule.dart';
import 'zone.dart';

Future<void> main(List<String> args) async {
  await initSupernova();

  for (final fileName in args) {
    final file = File(args.first);
    final (rules, zones) = parseZoneInformationFile(await file.readAsLines());
    logger.info('Parsed $fileName', {'rules': rules, 'zones': zones});
  }
}

// TODO: Support leap files

/// Original: `infile`
(Map<String, Rule>, Map<String, Zone>) parseZoneInformationFile(
  List<String> lines,
) {
  var lineIndex = 0;
  Line? readNextLine() {
    while (true) {
      if (lineIndex >= lines.length) return null;
      final line = Line.parse(lineIndex, lines[lineIndex]);
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

        zoneRules[zoneName] = [(rule, ruleEnd)];

        var previousLine = line;
        while (zoneRules[zoneName]!.last.$2 != null) {
          final newLine = readNextLine();
          if (newLine == null) {
            previousLine.logError('Expected zone continuation line not found');
            break;
          }

          final result = Zone.parseContinuation(newLine);
          if (result == null) continue;

          final (rule, ruleEnd) = result;
          zoneRules[zoneName]!.add((rule, ruleEnd));
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
    return Zone(
      name: it.key,
      rulesWithEnd: it.value
          .take(it.value.length - 1)
          .map((it) => (it.$1, it.$2!))
          .toList(),
      lastRule: it.value.last.$1,
    );
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
