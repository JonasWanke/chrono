import 'dart:io';

import 'package:chrono_timezone_parser/chrono_timezone_parser.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';

Future<void> main() async {
  final tableBuilder = TableBuilder();
  for (final file in timeZoneFiles) {
    final lines = await File('tz/$file').readAsLines();
    for (final line in lines) {
      tableBuilder.add(LineParser.parse(line).unwrap());
    }
  }
  final table = tableBuilder.build();

  final formatter = DartFormatter(
    languageVersion: DartFormatter.latestLanguageVersion,
  );

  // TODO(JonasWanke): add TZDB version to generated file

  await File(
    'lib/src/time_zones.dart',
  ).writeAsString(formatter.format(_buildTimezoneFile(table)));
}

// The timezone file contains the `Tz` enum with all time zones and their data.
String _buildTimezoneFile(Table table) {
  final buffer = StringBuffer('''
// ignore_for_file: constant_identifier_names

/// Time zones built from the tz database at compile time.
library;

import 'package:chrono/chrono.dart';

import '../chrono_timezone.dart';

enum Tz implements TimeZone {''');

  final zonesAndLinks = table.zonesets.keys
      .followedBy(table.links.keys)
      .toSet()
      .sorted();

  var isFirstZone = true;
  for (final zone in zonesAndLinks) {
    if (!isFirstZone) buffer.writeln(',');
    isFirstZone = false;

    final timespans = table.timespans(zone)!;
    buffer.writeln('''
/// $zone
${_convertBadChars(zone)}(
    '$zone',
    FixedTimespanSet(FixedTimespan('${timespans.first.name}', offsetSeconds: ${timespans.first.totalOffsetSeconds}), [
    ''');
    for (final (start, timespan) in timespans.rest) {
      buffer.writeln('''
      (
          $start,
          FixedTimespan(
            '${timespan.name}',
            offsetSeconds: ${timespan.totalOffsetSeconds},
          ),
      ),''');
    }
    buffer.writeln(']))');
  }
  buffer.writeln('''
;

  const Tz(this.tzId, this.timespans);

  static const nameToTz = {''');
  for (final zone in zonesAndLinks) {
    final variant = _convertBadChars(table.links[zone] ?? zone);
    buffer.write("'$zone': $variant,");
  }
  buffer.writeln('''
};
  static const lowercaseNameToTz = {''');
  for (final zone in zonesAndLinks) {
    final variant = _convertBadChars(table.links[zone] ?? zone);
    buffer.write("'${zone.toLowerCase()}': $variant,");
  }
  buffer.write('''
  };

  final String tzId;
  final FixedTimespanSet timespans;

  // First, search for a timespan that the local datetime falls into, then, if
  // it exists, check the two surrounding timespans (if they exist) to see if
  // there is any ambiguity.
  @override
  MappedLocalTime<TzOffset> offsetFromLocalDateTime(CDateTime local) {
    final timestamp = local.inUtc.durationSinceUnixEpoch.totalSeconds;
    final index = _binarySearch(
      timespans.length,
      (index) => timespans.localSpan(index).compareTo(timestamp),
    );
    return TzOffset.mapMappedLocalTime(this, switch (index) {
      null => const MappedLocalTime_None(),
      0 when timespans.length == 1 => MappedLocalTime_Single(timespans.get(0)),
      0 when timespans.localSpan(1).contains(timestamp) =>
        MappedLocalTime_Ambiguous(timespans.get(0), timespans.get(1)),
      0 => MappedLocalTime_Single(timespans.get(0)),
      final i when timespans.localSpan(i - 1).contains(timestamp) =>
        MappedLocalTime_Ambiguous(timespans.get(i - 1), timespans.get(i)),
      final i when i == timespans.length - 1 => MappedLocalTime_Single(
        timespans.get(i),
      ),
      final i when timespans.localSpan(i + 1).contains(timestamp) =>
        MappedLocalTime_Ambiguous(timespans.get(i), timespans.get(i + 1)),
      final i => MappedLocalTime_Single(timespans.get(i)),
    });
  }

  // Binary search for the required timespan. Any int is guaranteed to fall
  // within exactly one timespan, no matter what (so the `!` is safe).
  @override
  TzOffset offsetFromUtcDateTime(CDateTime utc) {
    final timestamp = utc.inUtc.durationSinceUnixEpoch.totalSeconds;
    final index = _binarySearch(
      timespans.length,
      (index) => timespans.utcSpan(index).compareTo(timestamp),
    )!;
    return TzOffset(this, timespans.get(index));
  }
}

int? _binarySearch(int length, Ordering Function(int index) compare) {
  var min = 0;
  var max = length;
  while (min < max) {
    final mid = min + ((max - min) >> 1);
    switch (compare(mid)) {
      case Ordering.less:
        min = mid + 1;
      case Ordering.equal:
        return mid;
      case Ordering.greater:
        max = mid;
    }
  }
  return null;
}
''');
  return buffer.toString();
}

/// Convert all '/' to '_', all '+' to 'Plus' and '-' to 'Minus', unless it's a
/// hyphen, in which case remove it.
///
/// This is so the names can be used as Dart identifiers.
String _convertBadChars(String name) {
  name = name.replaceAll('/', '__').replaceAll('+', 'Plus');
  final index = name.indexOf('-');
  if (index < 0) return name;

  return name.replaceAll(
    '-',
    index < name.length - 1 && RegExp(r'\d').hasMatch(name[index + 1])
        ? 'Minus'
        : '',
  );
}
