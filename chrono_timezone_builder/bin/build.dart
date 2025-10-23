import 'dart:io';

import 'package:chrono_timezone_parser/chrono_timezone_parser.dart';
import 'package:collection/collection.dart';
import 'package:dart_style/dart_style.dart';

Future<void> main() async {
  final version = await _detectIanaDbVersion();

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

  await File(
    'lib/src/time_zones.dart',
  ).writeAsString(formatter.format(_buildTimezoneFile(version, table)));
}

Future<String> _detectIanaDbVersion() async {
  for (final line in await File('tz/NEWS').readAsLines()) {
    if (!line.startsWith('Release ')) continue;

    return line.substring(8).split(' - ').first;
  }

  throw const FormatException(
    'Could not detect IANA Time Zone Database version from tz/NEWS',
  );
}

// The timezone file contains the `Tz` enum with all time zones and their data.
String _buildTimezoneFile(String version, Table table) {
  final buffer = StringBuffer('''
// ignore_for_file: constant_identifier_names

/// Time zones built from the tz database at compile time.
library;

import 'package:chrono/chrono.dart';

import '../chrono_timezone.dart';
import 'utils.dart';

const ianaTzdbVersion = '$version';

enum Tz implements TimeZone<Tz> {''');

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
${_zoneNameToLowerCamelCase(zone)}(
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

  factory Tz.fromJson(String json) {
    final tz = nameToTz[json];
    if (tz == null) {
      throw ArgumentError.value(json, 'json', 'Unknown time zone ID');
    }
    return tz;
  }

  static const nameToTz = {''');
  for (final zone in zonesAndLinks) {
    final variant = _zoneNameToLowerCamelCase(table.links[zone] ?? zone);
    buffer.write("'$zone': $variant,");
  }
  buffer.writeln('''
};
  static const lowercaseNameToTz = {''');
  for (final zone in zonesAndLinks) {
    final variant = _zoneNameToLowerCamelCase(table.links[zone] ?? zone);
    buffer.write("'${zone.toLowerCase()}': $variant,");
  }
  buffer.write('''
  };

  final String tzId;
  final FixedTimespanSet timespans;

  String toJson() => tzId;

  @override
  MappedLocalTime<ZonedDateTime<Tz>> with_ymd_and_hms(
    int year,
    int month,
    int day,
    int hour,
    int minute,
    int second,
  ) {
    return fromLocalDateTime(
      Date.fromRaw(
        year,
        month,
        day,
      ).unwrap().at(Time.from(hour, minute, second).unwrap()),
    );
  }

  @override
  ZonedDateTime<Tz> withDurationSinceUnixEpoch(TimeDelta duration) {
    return fromUtcDateTime(
      ZonedDateTime.fromDurationSinceUnixEpoch(duration).utcDateTime,
    );
  }

  // First, search for a timespan that the local datetime falls into, then, if
  // it exists, check the two surrounding timespans (if they exist) to see if
  // there is any ambiguity.
  @override
  MappedLocalTime<TzOffset> offsetFromLocalDateTime(CDateTime local) {
    final timestamp = local.inUtc.durationSinceUnixEpoch.totalSeconds;
    final index = binarySearch(
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

  @override
  MappedLocalTime<ZonedDateTime<Tz>> fromLocalDateTime(CDateTime local) {
    return offsetFromLocalDateTime(local).andThen(
      (offset) => ZonedDateTime.fromUtcDateTimeAndOffset(
        local.subOffset(offset.fix()),
        offset,
      ),
    );
  }

  // Binary search for the required timespan. Any int is guaranteed to fall
  // within exactly one timespan, no matter what (so the `!` is safe).
  @override
  TzOffset offsetFromUtcDateTime(CDateTime utc) {
    final timestamp = utc.inUtc.durationSinceUnixEpoch.totalSeconds;
    final index = binarySearch(
      timespans.length,
      (index) => timespans.utcSpan(index).compareTo(timestamp),
    )!;
    return TzOffset(this, timespans.get(index));
  }

  @override
  ZonedDateTime<Tz> fromUtcDateTime(CDateTime utc) {
    return ZonedDateTime.fromUtcDateTimeAndOffset(
      utc,
      offsetFromUtcDateTime(utc),
    );
  }

  @override
  String toString() => tzId;
}
''');
  return buffer.toString();
}

/// Also converts all '/' to '_', all '+' to 'Plus' and '-' to 'Minus', unless
/// it's a hyphen, in which case remove it.
String _zoneNameToLowerCamelCase(String name) {
  name = name
      .replaceAll('+', '_Plus_')
      .replaceAll(RegExp(r'-(?=\d)'), '_Minus_')
      .replaceAll('-', '_');

  return name
      .split('/')
      .map((it) {
        it = it
            .split('_')
            .map((it) => it[0].toUpperCase() + it.substring(1).toLowerCase())
            .join();
        return it[0].toLowerCase() + it.substring(1);
      })
      .join('_');
}
