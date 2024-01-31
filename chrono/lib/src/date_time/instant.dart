import 'dart:core' as core;
import 'dart:core';

import 'package:clock/clock.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:oxidized/oxidized.dart';

import '../json.dart';
import '../parser.dart';
import '../rounding.dart';
import '../time/duration.dart';
import '../utils.dart';
import 'date_time.dart';

/// https://en.wikipedia.org/wiki/Unix_time
@immutable
final class Instant
    with ComparisonOperatorsFromComparable<Instant>
    implements Comparable<Instant> {
  /// The UNIX epoch: 1970-01-01 at 00:00:00 in UTC.
  ///
  /// https://en.wikipedia.org/wiki/Unix_time
  static final unixEpoch =
      Instant.fromDurationSinceUnixEpoch(FractionalSeconds.zero);

  Instant.fromDurationSinceUnixEpoch(TimeDuration duration)
      : durationSinceUnixEpoch = duration.asFractionalSeconds;

  Instant.fromCore(core.DateTime dateTime)
      : durationSinceUnixEpoch =
            FractionalSeconds.microsecond * dateTime.microsecondsSinceEpoch;
  Instant.now({Clock? clockOverride})
      : this.fromCore((clockOverride ?? clock).now());

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
}

class InstantAsIsoStringJsonConverter
    extends JsonConverterWithParserResult<Instant, String> {
  const InstantAsIsoStringJsonConverter();

  @override
  Result<Instant, FormatException> resultFromJson(String json) =>
      Parser.parseInstant(json);
  @override
  String toJson(Instant object) => object.toString();
}

/// Encodes an [Instant] as an integer representing the number of milliseconds
/// that passed since the Unix epoch.
///
/// See also:
/// - [Instant.unixEpoch], which is the Unix epoch.
/// - [InstantAsEpochSecondsIntJsonConverter], which has a lower precision.
/// - [InstantAsIsoStringJsonConverter], which has a higher precision and is
///   human-readable.
class InstantAsEpochMillisecondsIntJsonConverter
    extends JsonConverter<Instant, int> {
  const InstantAsEpochMillisecondsIntJsonConverter({
    this.rounding = Rounding.nearestAwayFromZero,
  });

  final Rounding rounding;

  @override
  Instant fromJson(int json) =>
      Instant.fromDurationSinceUnixEpoch(Milliseconds(json));
  @override
  int toJson(Instant object) {
    return object.durationSinceUnixEpoch
        .roundToMilliseconds(rounding: rounding)
        .inMilliseconds;
  }
}

/// Encodes an [Instant] as an integer representing the number of seconds that
/// passed since the Unix epoch.
///
/// See also:
/// - [Instant.unixEpoch], which is the Unix epoch.
/// - [InstantAsEpochMillisecondsIntJsonConverter], which has a higher
///   precision.
/// - [InstantAsIsoStringJsonConverter], which has a higher precision and is
///   human-readable.
class InstantAsEpochSecondsIntJsonConverter
    extends JsonConverter<Instant, int> {
  const InstantAsEpochSecondsIntJsonConverter({
    this.rounding = Rounding.nearestAwayFromZero,
  });

  final Rounding rounding;

  @override
  Instant fromJson(int json) =>
      Instant.fromDurationSinceUnixEpoch(Seconds(json));
  @override
  int toJson(Instant object) {
    return object.durationSinceUnixEpoch
        .roundToSeconds(rounding: rounding)
        .inSeconds;
  }
}
