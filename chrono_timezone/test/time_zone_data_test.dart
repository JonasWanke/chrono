@TestOn('vm')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:chrono_timezone/chrono_timezone.dart';
import 'package:test/test.dart';

/// Compares the generated time zone data to `zic`, the reference
/// implementation, compiled from the same tz source files in `tz/`.
///
/// Both sides are explicit lists of transitions. Between two consecutive
/// transitions of their union both are constant, so checking each transition
/// and the second before it proves they are equal over the whole range.
///
/// This test is skipped if the `tz` submodule is not checked out or `zic` is
/// not available. Set the `ZIC` environment variable to use a specific binary.
///
/// On CI (the `CI` environment variable is `true`), missing prerequisites fail
/// the test instead, so that a broken setup can't pass unnoticed.
void main() {
  final unavailableReason = _unavailableReason();
  if (unavailableReason != null && _isCi) {
    test(
      'compared to zic',
      () => fail('Cannot compare to zic: $unavailableReason'),
    );
    return;
  }

  group('compared to zic', skip: unavailableReason, () {
    late Directory zicOutput;
    setUpAll(() => zicOutput = _compileWithZic());
    tearDownAll(() => zicOutput.deleteSync(recursive: true));

    test('all zones and links', () {
      var compared = 0;
      final differences = <String>[];
      for (final MapEntry(key: name, value: tz) in Tz.nameToTz.entries) {
        final file = File('${zicOutput.path}/$name');
        if (!file.existsSync()) {
          differences.add('$name: zic did not generate this zone');
          continue;
        }

        final result = _compare(
          expected: _parseTzif(file.readAsBytesSync()),
          actual: _timelineOf(tz),
        );
        compared += result.compared;
        differences.addAll(result.differences.map((it) => '$name: $it'));
      }

      // Guards against comparing (almost) nothing, e.g., if `zic` only wrote
      // compact files that omit most transitions.
      expect(compared, greaterThan(50000));
      expect(
        differences,
        isEmpty,
        reason:
            '${differences.length} differences, first ones:\n'
            '${differences.take(30).join('\n')}',
      );
    });
  });
}

/// The files that make up the tz database.
///
/// Keep in sync with `timeZoneFiles` in `chrono_timezone_parser`.
const _sourceFiles = [
  'africa',
  'antarctica',
  'asia',
  'australasia',
  'backward',
  'etcetera',
  'europe',
  'northamerica',
  'southamerica',
];

final _zic = Platform.environment['ZIC'] ?? 'zic';
final _isCi = Platform.environment['CI'] == 'true';

String? _unavailableReason() {
  if (!Directory('tz').existsSync()) {
    return 'the `tz` submodule is not checked out';
  }

  try {
    Process.runSync(_zic, ['--version']);
  } on ProcessException {
    return '`$_zic` is not available (set `ZIC` to the path of a zic binary)';
  }
  return null;
}

/// Compiles the tz source files with `-b fat`, so that the generated files
/// contain all transitions up to 2037 instead of relying on a POSIX TZ string.
Directory _compileWithZic() {
  final output = Directory.systemTemp.createTempSync('chrono_timezone_zic_');
  final result = Process.runSync(_zic, [
    '-b',
    'fat',
    '-d',
    output.path,
    ..._sourceFiles,
  ], workingDirectory: 'tz');
  if (result.exitCode != 0) {
    output.deleteSync(recursive: true);
    fail('zic failed (exit code ${result.exitCode}): ${result.stderr}');
  }
  return output;
}

// Comparison

/// The range in which transitions are compared.
///
/// The upper bound is the end of the 32-bit range, the lower one excludes the
/// placeholder transition that fat TZif files start with. Beyond the last
/// transition of a fat file, 2037, it stays constant, whereas our data
/// continues until 2100.
const _minInstant = -(1 << 40);
const _maxInstant = (1 << 31) - 1;

({int compared, List<String> differences}) _compare({
  required _Timeline expected,
  required _Timeline actual,
}) {
  final transitions = {
    ...expected.times,
    ...actual.times,
  }.where((it) => it > _minInstant && it <= _maxInstant).toList()..sort();

  var compared = 0;
  final differences = <String>[];
  for (final transition in transitions) {
    for (final instant in [transition - 1, transition]) {
      compared++;
      final expectedLocal = expected.at(instant);
      final actualLocal = actual.at(instant);
      if (expectedLocal == actualLocal) continue;

      differences.add(
        '${_describe(instant)}: expected $expectedLocal, got $actualLocal',
      );
    }
  }
  return (compared: compared, differences: differences);
}

String _describe(int instant) {
  final dateTime = DateTime.fromMillisecondsSinceEpoch(
    instant * 1000,
    isUtc: true,
  );
  return dateTime.toIso8601String();
}

// Timelines

/// The abbreviation and offset that apply during a period of time.
typedef _Local = ({String name, int offsetSeconds});

/// A list of [_Local]s, valid from the transition [times] at the same index.
///
/// [first] applies before the first transition.
class _Timeline(
  final _Local first,
  final List<int> times,
  final List<_Local> values,
) {
  /// The [_Local] that applies at the given [instant] (a Unix timestamp).
  _Local at(int instant) {
    // Find the number of transitions at or before [instant].
    var low = 0;
    var high = times.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (times[middle] <= instant) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low == 0 ? first : values[low - 1];
  }
}

_Timeline _timelineOf(Tz tz) {
  _Local local(FixedTimespan timespan) =>
      (name: timespan.name, offsetSeconds: timespan.offsetSeconds);

  final FixedTimespanSet(:first, :rest) = tz.timespans;
  return _Timeline(
    local(first),
    [for (final (time, _) in rest) time],
    [for (final (_, timespan) in rest) local(timespan)],
  );
}

// TZif parser

/// Parses a TZif file as specified in RFC 8536, using its 64-bit data block.
_Timeline _parseTzif(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  if (String.fromCharCodes(bytes.sublist(0, 4)) != 'TZif') {
    throw const FormatException('Missing TZif magic number');
  }

  const headerLength = 44;
  var header = _TzifHeader.read(data, 0);
  var position = headerLength;
  var timeSize = 4;
  if (bytes[4] >= 0x32 /* version '2' */ ) {
    // Skip the version 1 data block, which uses 32-bit transition times.
    position += header.dataLength(timeSize: timeSize);
    header = _TzifHeader.read(data, position);
    position += headerLength;
    timeSize = 8;
  }

  final times = [
    for (var i = 0; i < header.timeCount; i++)
      if (timeSize == 8)
        data.getInt64(position + i * 8)
      else
        data.getInt32(position + i * 4),
  ];
  position += header.timeCount * timeSize;

  final typeIndexes = bytes.sublist(position, position + header.timeCount);
  position += header.timeCount;

  // Each local time type is a 4-byte offset, a 1-byte DST flag, and a 1-byte
  // index into the abbreviation characters.
  final typesPosition = position;
  position += header.typeCount * 6;
  final characters = bytes.sublist(position, position + header.charCount);

  _Local type(int index) {
    final typePosition = typesPosition + index * 6;
    final nameStart = bytes[typePosition + 5];
    final nameEnd = characters.indexOf(0, nameStart);
    return (
      name: String.fromCharCodes(characters.sublist(nameStart, nameEnd)),
      offsetSeconds: data.getInt32(typePosition),
    );
  }

  return _Timeline(type(0), times, [
    for (final index in typeIndexes) type(index),
  ]);
}

class _TzifHeader(
  final int timeCount,
  final int typeCount,
  final int charCount,
  final int leapCount,
  final int isStdCount,
  final int isUtCount,
) {
  /// Reads the header at [position]: 4 bytes magic number, 1 byte version, 15
  /// reserved bytes, and six 4-byte counts.
  new read(ByteData data, int position)
    : this(
        data.getUint32(position + 32),
        data.getUint32(position + 36),
        data.getUint32(position + 40),
        data.getUint32(position + 28),
        data.getUint32(position + 24),
        data.getUint32(position + 20),
      );

  /// The length of the data block that follows the header.
  int dataLength({required int timeSize}) =>
      timeCount * timeSize +
      timeCount +
      typeCount * 6 +
      charCount +
      leapCount * (timeSize + 4) +
      isStdCount +
      isUtCount;
}
