import 'dart:core';
import 'dart:core' as core;

import 'package:clock/clock.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../parser.dart';
import '../time/duration.dart';
import '../utils.dart';
import 'date_time.dart';

/// https://en.wikipedia.org/wiki/Unix_time
@immutable
final class Instant
    with ComparisonOperatorsFromComparable<Instant>
    implements Comparable<Instant> {
  Instant.fromDurationSinceUnixEpoch(TimeDuration duration)
      : durationSinceUnixEpoch = duration.asFractionalSeconds;

  Instant.fromCore(core.DateTime dateTime)
      : durationSinceUnixEpoch =
            FractionalSeconds.microsecond * dateTime.microsecondsSinceEpoch;
  Instant.now({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now());

  factory Instant.fromJson(String json) => unwrapParserResult(parse(json));
  static Result<Instant, FormatException> parse(String value) =>
      Parser.parseInstant(value);

  final FractionalSeconds durationSinceUnixEpoch;

  DateTime get dateTimeInLocalZone =>
      DateTime.fromCore(asCoreDateTimeInLocalZone);
  DateTime get dateTimeInUtc => DateTime.fromCore(asCoreDateTimeInUtc);

  core.DateTime get asCoreDateTimeInLocalZone => _getDateTime(isUtc: false);
  core.DateTime get asCoreDateTimeInUtc => _getDateTime(isUtc: true);
  core.DateTime _getDateTime({required bool isUtc}) {
    return core.DateTime.fromMicrosecondsSinceEpoch(
      durationSinceUnixEpoch.roundToMicroseconds().inMicroseconds,
      isUtc: isUtc,
    );
  }

  Instant operator +(TimeDuration duration) =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch + duration);
  Instant operator -(TimeDuration duration) =>
      Instant.fromDurationSinceUnixEpoch(durationSinceUnixEpoch - duration);

  /// Returns `this - other`.
  FractionalSeconds difference(Instant other) =>
      durationSinceUnixEpoch - other.durationSinceUnixEpoch;

  @override
  int compareTo(Instant other) =>
      durationSinceUnixEpoch.compareTo(other.durationSinceUnixEpoch);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Instant &&
            durationSinceUnixEpoch == other.durationSinceUnixEpoch);
  }

  @override
  int get hashCode => durationSinceUnixEpoch.hashCode;

  @override
  String toString() => '${dateTimeInUtc}Z';

  String toJson() => toString();
}
