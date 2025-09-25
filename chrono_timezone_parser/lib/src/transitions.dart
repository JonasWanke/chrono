import 'package:chrono/chrono.dart';
import 'package:collection/collection.dart';
import 'package:deranged/deranged.dart';
import 'package:meta/meta.dart';

import '../chrono_timezone_parser.dart';

/// A set of timespans, separated by the instances at which the timespans
/// change over. There will always be one more timespan than transitions.
@immutable
class FixedTimespanSet {
  const FixedTimespanSet(this.first, this.rest);

  /// The first timespan, which is assumed to have been in effect up until
  /// the initial transition instant (if any). Each set has to have at
  /// least one timespan.
  final FixedTimespan first;

  /// The rest of the timespans, as a list of tuples, each containing:
  ///
  /// 1. A transition instant at which the previous timespan ends and the
  ///    next one begins, stored as a Unix timestamp.
  /// 2. The actual timespan to transition into.
  final List<(int, FixedTimespan)> rest;

  void _optimise() {
    var fromI = 0;
    var toI = 0;

    while (fromI < rest.length) {
      if (toI > 1) {
        final from = rest[fromI].$1;
        final to = rest[toI - 1].$1;
        if (from + rest[toI - 1].$2.totalOffsetSeconds <=
            to + rest[toI - 2].$2.totalOffsetSeconds) {
          rest[toI - 1] = (rest[toI - 1].$1, rest[fromI].$2);
          fromI++;
          continue;
        }
      }

      if (toI == 0 || rest[toI - 1].$2 != rest[fromI].$2) {
        rest[toI] = rest[fromI];
        toI++;
      }

      fromI++;
    }

    rest.removeRange(toI, rest.length);

    if (rest.isNotEmpty && first == rest[0].$2) {
      rest.removeAt(0);
    }
  }
}

/// An individual timespan with a fixed offset.
///
/// This mimics the `FixedTimespan` struct in `datetime::cal::zone`, except
/// instead of “total offset” and “is DST” fields, it has separate UTC and
/// DST fields. Also, the name is an owned `String` here instead of a slice.
@immutable
class FixedTimespan {
  const FixedTimespan(
    this.name, {
    required this.utcOffsetSeconds,
    required this.dstOffsetSeconds,
  });

  /// The abbreviation in use during this timespan.
  final String name;

  /// The number of seconds offset from UTC during this timespan.
  final int utcOffsetSeconds;

  /// The number of *extra* daylight-saving seconds during this timespan.
  final int dstOffsetSeconds;

  /// The total offset in effect during this timespan.
  int get totalOffsetSeconds => utcOffsetSeconds + dstOffsetSeconds;
}

class FixedTimespanSetBuilder {
  FixedTimespan? _first;
  final rest = <(int, FixedTimespan)>[];

  int? startTime;
  late int _untilTime;

  String addFixedSaving(
    TableZoneInfo timespan, {
    required int utcOffsetSeconds,
    required int dstOffsetSeconds,
    required bool insertStartTransition,
  }) {
    final startZoneId = timespan.format.format(
      utcOffsetSeconds,
      dstOffsetSeconds,
      null,
    );
    if (insertStartTransition) {
      rest.add((
        startTime!,
        FixedTimespan(
          startZoneId,
          utcOffsetSeconds: timespan.offsetSeconds,
          dstOffsetSeconds: dstOffsetSeconds,
        ),
      ));
      insertStartTransition = false;
    } else {
      _first = FixedTimespan(
        startZoneId,
        utcOffsetSeconds: utcOffsetSeconds,
        dstOffsetSeconds: dstOffsetSeconds,
      );
    }
    return startZoneId;
  }

  ({
    int dstOffsetSeconds,
    String? startZoneId,
    int startUtcOffset,
    int startDstOffset,
  })
  addMultipleSaving(
    TableZoneInfo timespan,
    List<TableRuleInfo> rules, {
    required int dstOffsetSeconds,
    required bool useUntil,
    required int utcOffsetSeconds,
    required bool insertStartTransition,
    required String? startZoneId,
    required int startUtcOffset,
    required int startDstOffset,
  }) {
    for (final year in const Range(Year(1800), Year(2100)).iter) {
      if (useUntil && year > timespan.endTime!.getYear()) break;

      final activatedRules = rules
          .where((it) => it.appliesToYear(year))
          .toList();

      while (true) {
        if (useUntil) {
          _untilTime =
              timespan.endTime!.toTimestamp() -
              utcOffsetSeconds -
              dstOffsetSeconds;
        }

        // Find the minimum rule and its start time based on the current
        // UTC and DST offsets.
        final earliest = minBy(
          activatedRules.mapIndexed(
            (index, it) => (
              index,
              it.absoluteDateTime(year, utcOffsetSeconds, dstOffsetSeconds),
            ),
          ),
          (it) => it.$2,
        );
        if (earliest == null) break;
        final (pos, earliestAt) = earliest;

        final earliestRule = activatedRules.removeAt(pos);

        if (useUntil && earliestAt >= _untilTime) break;

        dstOffsetSeconds = earliestRule.timeToAdd;

        if (insertStartTransition && earliestAt == startTime!) {
          insertStartTransition = false;
        }

        if (insertStartTransition) {
          if (earliestAt < startTime!) {
            startUtcOffset = timespan.offsetSeconds;
            startDstOffset = dstOffsetSeconds;

            startZoneId = timespan.format.format(
              utcOffsetSeconds,
              dstOffsetSeconds,
              earliestRule.letters,
            );
            continue;
          }

          if (startZoneId == null &&
              startUtcOffset + startDstOffset ==
                  timespan.offsetSeconds + dstOffsetSeconds) {
            startZoneId = timespan.format.format(
              utcOffsetSeconds,
              dstOffsetSeconds,
              earliestRule.letters,
            );
          }
        }

        rest.add((
          earliestAt,
          FixedTimespan(
            timespan.format.format(
              timespan.offsetSeconds,
              earliestRule.timeToAdd,
              earliestRule.letters,
            ),
            utcOffsetSeconds: timespan.offsetSeconds,
            dstOffsetSeconds: earliestRule.timeToAdd,
          ),
        ));
      }
    }
    return (
      dstOffsetSeconds: dstOffsetSeconds,
      startZoneId: startZoneId,
      startUtcOffset: startUtcOffset,
      startDstOffset: startDstOffset,
    );
  }

  FixedTimespanSet build() {
    rest.sortBy((it) => it.$1);
    final first =
        _first ?? rest.firstWhere((it) => it.$2.dstOffsetSeconds == 0).$2;
    return FixedTimespanSet(first, rest).._optimise();
  }
}

// TODO(JonasWanke): tests
// TODO(JonasWanke): remove OffsetName
// TODO(JonasWanke): add OffsetComponents
